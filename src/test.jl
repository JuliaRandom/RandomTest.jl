## AbstractFloat

test(::Type{Float64}) =
    Sized{Float64}(Frequency(10 => Small(33),
                             3  => Small(330),
                             1  => (NaN,))) do sz # NaN => special cases
        if isnan(sz)
            (NaN, Inf, -Inf, 0.0, -0.0)
        else
            AdHoc{Float64}() do rng
                r = rand(rng, CloseOpen12())^sz
                if sz >= -1 && rand(rng) < 0.1 # include some integers
                    r = floor(r)
                end
                ifelse(rand(rng, Bool), r, -r)
            end
        end
    end


## Integer

# TODO: do not restrict to Base.BitInteger
# (this is in part to have old tests with `Tester` pass)
function test(::Type{T}) where {T<:Base.BitInteger}
    Sized{T}(Nat(maxsize(T)/3)) do sz # TODO: handle argument
        if sz <= maxsize(T)
            make(T, Size(sz))
            # TODO: 1 is more frequent than 0, 0 might need to come up more often
        else # TODO: find better tuning of generation close to typemax(T)
            AdHoc{T}() do rng
                typemax(T) - rand(rng, Small(T))
            end
        end
    end
end


## Rational

test(::Type{Rational{T}}, sz::Real...) where {T} = test(Rational{T}, test(T, sz...))

function test(::Type{Rational{T}}, t::Distribution{T}) where T
    Stacked{Rational{T}}(t) do t
        AdHoc{Rational{T}}() do rng
            if rand(rng) < 0.07 # integers
                Rational{T}(rand(rng, t))
            else
                while true
                    a, b = rand(rng, t), rand(rng, t)
                    if Base.hastypemax(T) && T <: Signed
                        b == typemin(T) && continue
                        a == typemin(T) && iszero(b) && continue
                    end
                    (a, b) != (0, 0) && return Rational{T}(a, b)
                end
            end
        end
    end
end
