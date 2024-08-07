#pragma once

#include <Common/memcmpSmall.h>
#include <Columns/ColumnString.h>
#include <Functions/FunctionFactory.h>


namespace DB
{

namespace ErrorCodes
{
    extern const int LOGICAL_ERROR;
}


template <bool negative = false>
struct EmptyImpl
{
    /// If the function will return constant value for FixedString data type.
    static constexpr auto is_fixed_to_constant = false;

    static void vector(const ColumnString::Chars & /*data*/, const ColumnString::Offsets & offsets, PaddedPODArray<UInt8> & res)
    {
        size_t size = offsets.size();
        ColumnString::Offset prev_offset = 1;
        for (size_t i = 0; i < size; ++i)
        {
            res[i] = negative ^ (offsets[i] == prev_offset);
            prev_offset = offsets[i] + 1;
        }
    }

    /// Only make sense if is_fixed_to_constant.
    static void vectorFixedToConstant(const ColumnString::Chars & /*data*/, size_t /*n*/, UInt8 & /*res*/)
    {
        throw Exception("Logical error: 'vectorFixedToConstant method' is called", ErrorCodes::LOGICAL_ERROR);
    }

    static void vectorFixedToVector(const ColumnString::Chars & data, size_t n, PaddedPODArray<UInt8> & res)
    {
        size_t size = data.size() / n;
        for (size_t i = 0; i < size; ++i)
            res[i] = negative ^ memoryIsZeroSmallAllowOverflow15(data.data() + i * n, n);
    }

    static void array(const ColumnString::Offsets & offsets, PaddedPODArray<UInt8> & res)
    {
        size_t size = offsets.size();
        ColumnString::Offset prev_offset = 0;
        for (size_t i = 0; i < size; ++i)
        {
            res[i] = negative ^ (offsets[i] == prev_offset);
            prev_offset = offsets[i];
        }
    }

    static void map(const ColumnString::Offsets & offsets, PaddedPODArray<UInt8> & res, bool /*is_mysql*/)
    {
        array(offsets, res);
    }

    static void uuid(const ColumnUUID::Container & container, size_t n, PaddedPODArray<UInt8> & res)
    {
        for (size_t i = 0; i < n; ++i)
            res[i] = negative ^ (container[i].toUnderType() == 0);
    }

    static void ipv6(const ColumnIPv6::Container & container, size_t n, PaddedPODArray<UInt8> & res)
    {
        for (size_t i = 0; i < n; ++i)
            res[i] = negative ^ (container[i].toUnderType() == 0);
    }

    static void ipv4(const ColumnIPv4::Container & container, size_t n, PaddedPODArray<UInt8> & res)
    {
        for (size_t i = 0; i < n; ++i)
            res[i] = negative ^ (container[i].toUnderType() == 0);
    }

    static bool isCompilable(const DataTypes &)
    {
        return false;
    }
    static llvm::Value * compileString(llvm::IRBuilderBase & , const DataTypes & , Values &  )
    {
        return nullptr;
    }
    static llvm::Value * compileFixedString(llvm::IRBuilderBase & , const DataTypes & , Values &  )
    {
        return nullptr;
    }
    static llvm::Value * compileArray(llvm::IRBuilderBase & , const DataTypes & , Values &  )
    {
        return nullptr;
    }
    static llvm::Value * compileMap(llvm::IRBuilderBase & , const DataTypes & , Values &  )
    {
        return nullptr;
    }
    static llvm::Value * compileUuid(llvm::IRBuilderBase & , const DataTypes & , Values &  )
    {
        return nullptr;
    }
};

}
