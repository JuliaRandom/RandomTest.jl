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
        else # TODO: find better tuning of generation close to typemax(T)
            AdHoc{T}() do rng
                typemax(T) - rand(rng, Small(T))
            end
        end
    end
end
