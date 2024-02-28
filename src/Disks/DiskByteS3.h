/*
 * Copyright 2023 Bytedance Ltd. and/or its affiliates.
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

#pragma once

#include <tuple>
#include <optional>
#include <Disks/IDisk.h>
#include <IO/ReadBufferFromFileBase.h>
#include <IO/WriteBufferFromFileBase.h>
#include <IO/S3Common.h>
#include <Storages/MergeTree/MergeTreeDataPartChecksum.h>
#include <aws/s3/S3Client.h>
#include <IO/RemoteFSReader.h>

namespace DB
{

namespace ErrorCodes
{
    extern const int NOT_IMPLEMENTED;
}

class DiskByteS3Reservation;

class DiskByteS3: public IDisk
{
public:
    friend class DiskByteS3Reservation;

    static constexpr auto DATA_FILE = "data";

    DiskByteS3(const String& name_, const String& root_prefix_, const String& bucket_,
        const std::shared_ptr<Aws::S3::S3Client>& client_);

    virtual const String & getName() const override { return name; }

    virtual ReservationPtr reserve(UInt64 bytes) override;

    virtual UInt64 getID() const override;

    virtual const String & getPath() const override { return root_prefix; }

    virtual UInt64 getTotalSpace() const override { return std::numeric_limits<UInt64>::max(); }

    virtual UInt64 getAvailableSpace() const override { return std::numeric_limits<UInt64>::max(); }

    virtual UInt64 getUnreservedSpace() const override { return std::numeric_limits<UInt64>::max(); }

    virtual UInt64 getKeepingFreeSpace() const override { return 0; }

    virtual bool exists(const String & path) const override;

    virtual bool isFile(const String & ) const override { throw Exception("isFile is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual bool isDirectory(const String & ) const override { throw Exception("isDirecotry is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual size_t getFileSize(const String & path) const override;

    virtual void createDirectory(const String & ) override { /*No op*/ }

    virtual void createDirectories(const String & ) override { /*No op*/ }

    virtual void clearDirectory(const String & ) override { throw Exception("clearDirectory is not implemnted in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual void moveDirectory(const String & , const String & ) override { throw Exception("moveDirecotry is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual DiskDirectoryIteratorPtr iterateDirectory(const String & ) override;

    virtual void createFile(const String & ) override { throw Exception("createFile is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual void moveFile(const String & , const String & ) override { throw Exception("moveFile is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED);}

    virtual void replaceFile(const String & , const String & ) override { throw Exception("replaceFile is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual void copy(const String & , const std::shared_ptr<IDisk> & , const String & ) override { throw Exception("copy is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual void listFiles(const String & path, std::vector<String> & file_names) override;

    virtual std::unique_ptr<ReadBufferFromFileBase> readFile(
        const String & path,
        const ReadSettings& settings) const override;

    virtual std::unique_ptr<WriteBufferFromFileBase> writeFile(
        const String & path,
        const WriteSettings& settings) override;

    virtual void removeFile(const String & path) override;

    virtual void removeFileIfExists(const String & path) override;

    /// Convert to no-op when there is no object under prefix `path`, otherwise throw exception
    virtual void removeDirectory(const String & path) override;

    virtual void removeRecursive(const String & path) override;

    virtual void setLastModified(const String & , const Poco::Timestamp & ) override { throw Exception("setLastModified is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual Poco::Timestamp getLastModified(const String & ) override { throw Exception("getLastModified is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual void setReadOnly(const String & ) override { throw Exception("setReadOnly is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual void createHardLink(const String & , const String & ) override { throw Exception("createHarLink is not implemented in DiskByteS3", ErrorCodes::NOT_IMPLEMENTED); }

    virtual DiskType::Type getType() const override { return DiskType::Type::ByteS3; }

    virtual bool supportRenameTo() override { return false; }

    virtual String getTableRelativePathOnDisk(const String &) override {return "";}

    // Non virtual functions
    const String& getS3Bucket() const { return s3_util.getBucket(); }
    std::shared_ptr<Aws::S3::S3Client> getS3Client() const { return s3_util.getClient(); }
    const S3::S3Util& getS3Util() const { return s3_util; }

    // This function calls HeadObject, instead of the poorly performing ListObjects used in exists()
    // If you want to check if a file exists, we strongly suggest using this function
    bool fileExists(const String & file_path) const;

    // remove the data file of the given part
    // removeRecursive() should be avoided, because it calls the poorly performing ListObjects
    void removePart(const String & part_path);

private:
    bool tryReserve(UInt64 bytes);

    static String trimPrefix(const String& prefix, const String& key);

    const UInt64 disk_id;
    String name;
    String root_prefix;
    S3::S3Util s3_util;

    std::shared_ptr<RemoteFSReaderOpts> reader_opts;

    UInt64 reserved_bytes;
    UInt64 reservation_count;

    static std::mutex reservation_mutex;
};

using DiskByteS3Ptr = std::shared_ptr<DiskByteS3>;

}
