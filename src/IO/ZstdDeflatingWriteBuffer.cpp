
/*
 * Copyright 2016-2023 ClickHouse, Inc.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/*
 * This file may have been modified by Bytedance Ltd. and/or its affiliates (“ Bytedance's Modifications”).
 * All Bytedance's Modifications are Copyright (2023) Bytedance Ltd. and/or its affiliates.
 */

#include <IO/ZstdDeflatingWriteBuffer.h>
#include <Common/MemoryTracker.h>
#include <Common/Exception.h>

namespace DB
{
namespace ErrorCodes
{
    extern const int ZSTD_ENCODER_FAILED;
}

ZstdDeflatingWriteBuffer::ZstdDeflatingWriteBuffer(
    std::unique_ptr<WriteBuffer> out_, int compression_level, size_t buf_size, char * existing_memory, size_t alignment)
    : BufferWithOwnMemory<WriteBuffer>(buf_size, existing_memory, alignment), out(std::move(out_))
{
    cctx = ZSTD_createCCtx();
    if (cctx == nullptr)
        throw Exception(ErrorCodes::ZSTD_ENCODER_FAILED, "zstd stream encoder init failed: zstd version: {}", ZSTD_VERSION_STRING);
    size_t ret = ZSTD_CCtx_setParameter(cctx, ZSTD_c_compressionLevel, compression_level);
    if (ZSTD_isError(ret))
        throw Exception(ErrorCodes::ZSTD_ENCODER_FAILED, "zstd stream encoder option setting failed: error code: {}; zstd version: {}", ret, ZSTD_VERSION_STRING);
    ret = ZSTD_CCtx_setParameter(cctx, ZSTD_c_checksumFlag, 1);
    if (ZSTD_isError(ret))
        throw Exception(ErrorCodes::ZSTD_ENCODER_FAILED, "zstd stream encoder option setting failed: error code: {}; zstd version: {}", ret, ZSTD_VERSION_STRING);

    input = {nullptr, 0, 0};
    output = {nullptr, 0, 0};
}


ZstdDeflatingWriteBuffer::~ZstdDeflatingWriteBuffer()
{
    /// FIXME move final flush into the caller
    MemoryTracker::LockExceptionInThread lock(VariableContext::Global);

    finish();

    try
    {
        int err = ZSTD_freeCCtx(cctx);
        /// This is just in case, since it is impossible to get an error by using this wrapper.
        if (unlikely(err))
            throw Exception(ErrorCodes::ZSTD_ENCODER_FAILED, "ZSTD_freeCCtx failed: error: '{}'; zstd version: {}", ZSTD_getErrorName(err), ZSTD_VERSION_STRING);
    }
    catch (...)
    {
        /// It is OK not to terminate under an error from ZSTD_freeCCtx()
        /// since all data already written to the stream.
        tryLogCurrentException(__PRETTY_FUNCTION__);
    }
}

void ZstdDeflatingWriteBuffer::nextImpl()
{
    if (!offset())
        return;

    ZSTD_EndDirective mode = ZSTD_e_flush;

    input.src = reinterpret_cast<unsigned char *>(working_buffer.begin());
    input.size = offset();
    input.pos = 0;

    try
    {
        bool ended = false;
        do
        {
            out->nextIfAtEnd();

            output.dst = reinterpret_cast<unsigned char *>(out->buffer().begin());
            output.size = out->buffer().size();
            output.pos = out->offset();


            size_t compression_result = ZSTD_compressStream2(cctx, &output, &input, mode);
            if (ZSTD_isError(compression_result))
                throw Exception(
                    ErrorCodes::ZSTD_ENCODER_FAILED, "Zstd stream encoding failed: error: '{}'; zstd version: {}", ZSTD_getErrorName(compression_result), ZSTD_VERSION_STRING);

            out->position() = out->buffer().begin() + output.pos;

            bool everything_was_compressed = (input.pos == input.size);
            bool everything_was_flushed = compression_result == 0;

            ended = everything_was_compressed && everything_was_flushed;
        } while (!ended);
    }
    catch (...)
    {
        /// Do not try to write next time after exception.
        out->position() = out->buffer().begin();
        throw;
    }
}

void ZstdDeflatingWriteBuffer::finish()
{
    if (finished)
        return;

    try
    {
        finishImpl();
        out->finalize();
        finished = true;
    }
    catch (...)
    {
        /// Do not try to flush next time after exception.
        out->position() = out->buffer().begin();
        finished = true;
        throw;
    }
}

void ZstdDeflatingWriteBuffer::finishImpl()
{
    next();

    out->nextIfAtEnd();

    input.src = reinterpret_cast<unsigned char *>(working_buffer.begin());
    input.size = offset();
    input.pos = 0;

    output.dst = reinterpret_cast<unsigned char *>(out->buffer().begin());
    output.size = out->buffer().size();
    output.pos = out->offset();

    size_t remaining = ZSTD_compressStream2(cctx, &output, &input, ZSTD_e_end);
    if (ZSTD_isError(remaining))
        throw Exception(ErrorCodes::ZSTD_ENCODER_FAILED, "zstd stream encoder end failed: zstd version: {}", ZSTD_VERSION_STRING);
    out->position() = out->buffer().begin() + output.pos;
}

}
