#include <Functions/FunctionNumericPredicate.h>
#include <Functions/FunctionFactory.h>
#include <common/bit_cast.h>
#include <type_traits>


namespace DB
{
namespace
{

struct IsFiniteImpl
{
    /// Better implementation, because isinf, isfinite, isnan are not inlined for unknown reason.
    /// Assuming IEEE 754.
    /// NOTE gcc 7 doesn't vectorize this loop.

    static constexpr auto name = "isFinite";
    template <typename T>
    static bool execute(const T t)
    {
        if constexpr (std::is_same_v<T, float>)
            return (bit_cast<uint32_t>(t)
                 & 0b01111111100000000000000000000000)
                != 0b01111111100000000000000000000000;
        else if constexpr (std::is_same_v<T, double>)
            return (bit_cast<uint64_t>(t)
                 & 0b0111111111110000000000000000000000000000000000000000000000000000)
                != 0b0111111111110000000000000000000000000000000000000000000000000000;
        else
        {
            (void)t;
            return true;
        }
    }
};

using FunctionIsFinite = FunctionNumericPredicate<IsFiniteImpl>;

}

REGISTER_FUNCTION(IsFinite)
{
    factory.registerFunction<FunctionIsFinite>();
}

}
