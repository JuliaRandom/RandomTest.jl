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

scale(t::Real, sz::Sized{X}) where {X} = Sized{X}(sz.dist, sz.sz, sz.scale * t)

show(io::IO, s::Sized) =
    println(io, "Sized{", gentype(s), "}(", s.dist, ", ", s.sz, ", ", s.scale, ")")


## Staged

struct Staged{X,D<:Function,S} <: Distribution{X}
    dist::D
    inner::S
    scale::Float64

    Staged{X}(dist::D, inner::S, scale::Real=1.0) where {X,D,S} =
        new{X,D,S}(dist, inner, scale)
end

function Staged(dist::D, inner) where {D<:Function} # specialize on dist
    N = gentype(inner)
    X = gentype(Core.Compiler.return_type(dist, (N,)))
    Staged{X}(dist, inner)
end

function rand(rng::AbstractRNG, sp::SamplerTrivial{<:Staged})
    x = rand(rng, sp[].inner)
    d = scale(sp[].scale, sp[].dist(x))
    rand(rng, d)
end

show(io::IO, s::Staged) =
    println(io, "Staged{", gentype(s), "}(", s.dist, ", ", s.inner, ")")

scale(t::Real, s::Staged{X}) where {X} = Staged{X}(s.dist, s.inner, s.scale * t)


## Stacked

# like Staged, but forwards directly the inner distribution instead of sampling
# from it first
# the point is that Stacked delegates scaling operations to inner, like Sized

struct Stacked{X,D<:Function,S} <: Distribution{X}
    dist::D
    inner::S

    Stacked{X}(dist::D, inner::S) where {X,D,S} = new{X,D,S}(dist, inner)
end

function Stacked(dist::D, inner) where {D<:Function} # specialize on dist
    N = gentype(inner)
    X = gentype(Core.Compiler.return_type(dist, (N,)))
    Stacked{X}(dist, inner)
end

rand(rng::AbstractRNG, sp::SamplerTrivial{<:Stacked}) =
    rand(rng, sp[].dist(sp[].inner))

scale(t::Real, s::Stacked{X}) where {X} = Stacked{X}(s.dist, scale(t, s.inner))

show(io::IO, s::Stacked) =
    println(io, "Stacked{", gentype(s), "}(", s.dist, ", ", s.inner, ")")


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

scale(t::Real, a::Abs) = Abs(scale(t, a.d))

ratio(t::Real, a::Abs) = ratio(t, a.d)

show(io::IO, p::Abs) = println(io, "Abs(", p.d, ")") # don't show gentype, shown by p.d


## Frequency

# like MixtureModel (might be deleted when depending on proper package implementing it)

struct Frequency{X,D} <: Distribution{X}
    c::Categorical{Int}
    d::D

    function Frequency{X}(freqs::Union{Tuple,AbstractVector{<:Pair}}) where {X}
        c = Categorical(f[1] for f in freqs)
        d = collect(f[2] for f in freqs)
        new{X,typeof(d)}(c, d)
    end
end

function Frequency(freqs::Union{Tuple,AbstractVector{<:Pair}})
    X = foldl(typejoin, (gentype(f[2]) for f in freqs); init = Union{});
    Frequency{X}(freqs)
end

Frequency{X}(freqs::Pair...) where {X} = Frequency{X}(freqs)
Frequency(freqs::Pair...) = Frequency(freqs)

function rand(rng::AbstractRNG, sp::SamplerTrivial{<:Frequency})
    n = rand(rng, sp[].c)
    rand(rng, sp[].d[n])
end

function show(io::IO, f::Frequency)
    print(io, "Frequency{", gentype(f), "}(")
    ps = [f.c.cdf[1]; diff(f.c.cdf);] # TODO: factor out
    join(io, (ps[i] => f.d[i] for i in eachindex(ps)), ", ")
    print(io, ")")
end


## AdHoc

# TODO: find a better name

struct AdHoc{X,F} <: Distribution{X}
    f::F

    AdHoc{X}(f::F) where {X,F} = new{X,F}(f)
end

AdHoc(f::F) where {F} = AdHoc{Core.Compiler.return_type(f, (AbstractRNG,))}(f)

rand(rng::AbstractRNG, sp::SamplerTrivial{<:AdHoc}) = sp[].f(rng)

show(io::IO, d::AdHoc) = println(io, "AdHoc{", gentype(d), "}(", d.f, ")")
