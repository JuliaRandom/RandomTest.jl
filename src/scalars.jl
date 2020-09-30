## Small

struct Small{T<:Real} <: Distribution{T}
    scale::Float64
end

Small(::Type{T}=Float64, scale::Real=33.0) where {T} = Small{T}(scale)
Small(scale::Real) = Small(Float64, scale)

function rand(rng::AbstractRNG, sp::SamplerTrivial{Small{T}}) where {T<:AbstractFloat}
    sc = sp[].scale * 0.98 # to try to get a mean ≈ to sp[].scale
    a = 0.66 * randn(rng, T) * sc * (1.0 + abs(randn(rng)))
    b = 0.33 * rand(rng, (1.0, -1.0)) * randexp(rng) * sc
    a + b
end

function rand(rng::AbstractRNG, sp::SamplerTrivial{Small{T}}) where {T<:Integer}
    while true
        x = rand(Small(sp[].scale))
        if Base.hastypemax(T)
            typemin(T) <= x <= typemax(T) || continue
        end
        return round(T, x)
    end
end
