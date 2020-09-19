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
