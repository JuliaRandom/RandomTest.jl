module RandomTest

using Random: AbstractRNG, SamplerSimple, SamplerTag
import Random: rand, Sampler

using RandomExtensions: Cont, Distribution, make, Make1, Repetition

export make, Size, test


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


## Tester ####################################################################

struct Tester{T} <: Distribution{T} end

test(::Type{T}) where {T} = Tester{T}()


### <:Integer

# TODO: specialize Bool
Sampler(::Type{RNG}, d::Tester{T}, n::Repetition
        ) where {RNG<:AbstractRNG,T<:Integer} =
    SamplerSimple(d, Sampler(RNG, minsize(T):maxsize(T), n))

function rand(rng::AbstractRNG, sp::SamplerSimple{Tester{T}}) where T
    sz = rand(rng, sp.data)
    rand(rng, make(T, Size(sz)))
end


### Integer

const test_Integer = [Base.BitInteger_types...; Bool]

Sampler(::Type{RNG}, d::Tester{Integer}, n::Repetition
        ) where {RNG<:AbstractRNG} =
    SamplerTag{Cont{Integer}}(Sampler(RNG, test_Integer, n))

function rand(rng::AbstractRNG, sp::SamplerTag{Cont{Integer}})
    T = rand(rng, sp.data)
    rand(rng, test(T))
end


end # module
