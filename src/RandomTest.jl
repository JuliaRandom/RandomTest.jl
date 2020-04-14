module RandomTest

using Random: AbstractRNG
import Random: Sampler

using RandomExtensions: make, Make1, Repetition

export make, Size


## Size ######################################################################

struct Size
    sz::Int
end

minsize(::Type{<:Integer}) = 0
maxsize(::Type{T}) where {T <: Base.BitInteger} = 8*sizeof(T) - (T <: Signed)
maxsize(::Type{Bool}) = 1

function Sampler(::Type{RNG}, d::Make1{T,Size},
                 r::Repetition) where T <: Integer where RNG <:AbstractRNG
    sz = d[1].sz
    minsize(T) <= sz <= maxsize(T) || throw_invalid_size(sz, maxsize(T), T)
    if T === Bool
        Sampler(RNG, false:Bool(sz), r)
    else
        if T <: Signed
            Sampler(RNG, -T(2)^sz:T(2)^sz - T(1), r)
        else
            Sampler(RNG, T(0):T(2)^sz - T(1), r)
        end
    end
end

@noinline function throw_invalid_size(sz, maxsz, T)
    throw(ArgumentError(
        "size for type $T must satisfy 0 <= size < $maxsz (got $sz)"))
end

end # module
