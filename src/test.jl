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

### BitInteger

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

### BigInt

sizedist(::Type{BigInt}) = Frequency(3  => Nat(10),
                                     10 => Nat(33),
                                     2  => Nat(150))

sizedist(::Type{BigInt}, sz::Real) = Nat(sz)

function test(::Type{BigInt}, sz...)
    Sized{BigInt}(sizedist(BigInt, sz...)) do sz
        make(BigInt, Size(sz))
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


## Array


sizedist(::Type{<:Array}, sz::Real) = Nat(sz)
sizedist(::Type{<:Array}, sz) = sz

function test(::Type{Array{T,N}}, Tdist, sz=33.0) where {T,N}
    sd = sizedist(Array{T,N}, sz)
    Sized{Array{T,N}}(sd) do sz
        dims = N == 1 ? sz :
            rand(Nat(1+ceil(Int, sz^(1/N))), NTuple{N}) # TODO: use a dist a dims when
                                                        # RandomExtensions supports it
        make(Array{T,N}, scale(0.5*(ratio(sz, sd)), Tdist), dims)
        # TODO: refine (too often empty for N > 1)
    end
end

test(::Type{Array{T,N}}, sz::Real=33.0) where {T,N} = test(Array{T,N}, test(T), sz)
test(::Type{Array{T,N}}, ::Nothing, sz) where {T,N} = test(Array{T,N}, test(T), sz)

test(::Type{Array{T,N} where T}, Tdist, sz...) where {N} =
    test(Array{gentype(Tdist),N}, Tdist, sz...)
