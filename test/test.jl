@testset "AbstractFloat" begin
    t = test(Float64)
    @test rand(t) isa Float64
    @test gentype(t) == Float64
    v = rand(t, Set, 1000) # from RandomExtensions; must use a Set for `NaN in` to work
    @test NaN in v && Inf in v && -Inf in v && 0.0 in v && -0.0 in v && any(isinteger, v)
    # TODO: test `scale` better
    @test rand(scale(.3, t), 3) isa Vector{Float64}
end

@testset "BitInteger" begin
    for T = Base.BitInteger_types
        t = test(T)
        @test rand(t) isa T
        @test gentype(t) == T
        v = rand(t, 2000)
        @test 0 in v
        @test !isempty(intersect(v, [typemax(T)-T(i) for i = 0:20]))
    end
    for T = (Int, UInt)
        t = test(T)
        v = rand(t, 1000)
        @test 16 < mean(log2.(0.01 .+ filter(!=(typemin(T)), abs.(v)))) < 23
        t = scale(0.5, t)
        v = rand(t, 1000)
        @test 7 < mean(log2.(0.01 .+ filter(!=(typemin(T)), abs.(v)))) < 12
    end
end

@testset "BigInt" begin
    t = test(BigInt)
    @test rand(t) isa BigInt
    @test gentype(t) == BigInt
    v = rand(t, 500)
    @test 0 in v
    @test 30 < mean(filter(isfinite, log2.(abs.(v)))) < 60 # very roughly

    v = rand(scale(10, t), 500)
    @test 300 < mean(filter(isfinite, log2.(abs.(v)))) < 600 # very roughly
end

@testset "Rational" begin
    for T = [BigInt, Base.BitInteger_types...]
        t = test(Rational{T})
        @test rand(t) isa Rational{T}
        @test gentype(t) == Rational{T}
        v = rand(t, 1000)
        @test 0 in v
        @test any(!isfinite, v)
        @test any(x -> !iszero(x) && isinteger(x), v)
    end
    # TODO: test `scale`
    @test rand(scale(.3, test(Rational{Int})), 3) isa Vector{Rational{Int}}
end

@testset "Array" begin
    for N = 1:4
        for d in (test(Array{Int,N}), test(Array{Int,N}, 33), test(Array{Int,N}))
            @test gentype(d) == Array{Int,N}
            @test rand(d) isa Array{Int,N}
        end
    end
    d = test(Array{Int, rand(1:9)}, 1:3)
    @test all(∈(1:3), rand(d))

    d = test(Vector, 1:9, 1:3)
    @test gentype(d) == Vector{Int}
    v = rand(d)
    @test length(v) ∈ 1:3
    @test all(∈(1:9), v)

    d = test(Matrix, test(UInt), 3)
    @test gentype(d) == Matrix{UInt}
    @test rand(d) isa Matrix{UInt}
end
