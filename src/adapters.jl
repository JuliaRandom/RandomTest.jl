## Sized

struct Sized{X,D<:Function,S} <: Distribution{X}
    dist::D
    sz::S
    scale::Float64

    Sized{X}(dist::D, sz::S, scale::Real=1.0) where {X,D,S} =
        new{X,D,S}(dist, sz, scale)
end

function Sized(dist::D, sz) where {D<:Function} # specialize on dist
    N = gentype(sz)
    X = gentype(Core.Compiler.return_type(dist, (N,)))
    Sized{X}(dist, sz)
end

function rand(rng::AbstractRNG, sp::SamplerTrivial{<:Sized})
    sized = sp[]
    sz = rand(rng, sized.sz)
    T = typeof(sz)
    sz *= sized.scale
    sz = T <: Integer ? round(T, sz) :
                        convert(T, sz)
    rand(rng, sized.dist(sz))
end

show(io::IO, s::Sized) =
    println(io, "Sized{", gentype(s), "}(", s.dist, ", ", s.sz, ", ", s.scale, ")")


## Staged

struct Staged{X,D<:Function,S} <: Distribution{X}
    dist::D
    inner::S

    Staged{X}(dist::D, inner::S) where {X,D,S} = new{X,D,S}(dist, inner)
end

function Staged(dist::D, inner) where {D<:Function} # specialize on dist
    N = gentype(inner)
    X = gentype(Core.Compiler.return_type(dist, (N,)))
    Staged{X}(dist, inner)
end

rand(rng::AbstractRNG, sp::SamplerTrivial{<:Staged}) =
    rand(rng, sp[].dist(rand(rng, sp[].inner)))

show(io::IO, s::Staged) =
    println(io, "Staged{", gentype(s), "}(", s.dist, ", ", s.inner, ")")


## Abs

struct Abs{X,D} <: Distribution{X}
    d::D

    Abs(d::D) where {D} = new{gentype(d),D}(d)
end

Sampler(::Type{RNG}, p::Abs, n::Repetition) where {RNG<:AbstractRNG} =
    SamplerSimple(p, Sampler(RNG, p.d, n))

rand(rng::AbstractRNG, p::SamplerSimple{<:Abs}) = abs(rand(rng, p.data))

# work around the fact that abs(typemin(T)) can be == typemin(T)
# so we currently enforce that the result of Abs must be >= 0
# (this is not set in stone)
rand(rng::AbstractRNG, p::SamplerSimple{<:Abs{<:Integer}}) =
    while true
        x = abs(rand(rng, p.data))
        x < 0 || return x
    end

show(io::IO, p::Abs) = println(io, "Abs(", p.d, ")") # don't show gentype, shown by p.d
