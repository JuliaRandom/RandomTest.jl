module RandomTest

import Base: show

using Random: AbstractRNG, gentype, randexp, randn
import Random: rand, Sampler

using RandomExtensions: Cont, Distribution, make, Make1, Repetition,
                        SamplerSimple, SamplerTag, SamplerTrivial,
                        Categorical, CloseOpen12

export make, randt, Size, test
export Sized, Staged, Stacked, Abs, Frequency, AdHoc
export Small, Nat

include("scalars.jl")
include("adapters.jl")
include("test.jl")


## randt #####################################################################

randt(                  ::Type{X}=Float64) where {X} = rand(     test(X))
randt(rng::AbstractRNG, ::Type{X}=Float64) where {X} = rand(rng, test(X))

randt(                  dims::Integer...) = rand(     test(Float64), dims...)
randt(rng::AbstractRNG, dims::Integer...) = rand(rng, test(Float64), dims...)

randt(                  ::Type{X}, dims...) where {X} =
    rand(     test(X), dims...)

randt(rng::AbstractRNG, ::Type{X}, dims...) where {X} =
    rand(rng, test(X), dims...)


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
    sampler_tester(RNG, d, n, Val(isconcretetype(T)))

sampler_tester(::Type{RNG}, d::Tester{T}, n, concrete::Val{true}
               ) where {RNG,T<:Integer} =
    SamplerSimple(d, Sampler(RNG, minsize(T):maxsize(T), n))

function rand(rng::AbstractRNG, sp::SamplerSimple{Tester{T}}
              ) where T <: Integer
    sz = rand(rng, sp.data)
    rand(rng, make(T, Size(sz)))
end


### non concrete types

const test_registered = [Base.BitInteger_types...; Bool]

test_select(::Type{T}) where T = filter(X -> X <: T, test_registered)

sampler_tester(::Type{RNG}, d::Tester{T}, n::Repetition, concrete::Val{false},
               ) where {RNG<:AbstractRNG,T} =
    SamplerTag{Cont{Integer}}(Sampler(RNG, test_select(T), n))

function rand(rng::AbstractRNG, sp::SamplerTag{Cont{T}}) where T
    X = rand(rng, sp.data)
    rand(rng, test(X))
end


## floats ####################################################################

function rand(rng::AbstractRNG, sp::SamplerTrivial{Tester{Float64}})
    u = rand(rng, UInt64)
    e = Base.exponent_mask(Float64) & u
    if e == 0 || e == Base.exponent_mask(Float64)
        if rand(rng, Bool)
            u &= ~Base.significand_mask(Float64) # set to infinity or 0.0
        end
    end
    reinterpret(Float64, u)
end


## singleton types ###########################################################

test(::Type{Nothing}) = (nothing,)
test(::Type{Missing}) = (missing,)


## Pair ######################################################################

test(::Type{Pair{K,V}}) where {K,V} = make(Pair{K,V}, test(K), test(V))


## Tuple #####################################################################

test(::Type{T}) where {T<:Tuple} = make(Tuple, test.(fieldtypes(T))...)


end # module
