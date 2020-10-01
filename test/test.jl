@testset "AbstractFloat" begin
    t = test(Float64)
    @test rand(t) isa Float64
    @test gentype(t) == Float64
    v = rand(t, Set, 1000) # from RandomExtensions; must use a Set for `NaN in` to work
    @test NaN in v && Inf in v && -Inf in v && 0.0 in v && -0.0 in v && any(isinteger, v)
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
end

@testset "Rational" begin
    for T = Base.BitInteger_types
        t = test(Rational{T})
        @test rand(t) isa Rational{T}
        @test gentype(t) == Rational{T}
        v = rand(t, 1000)
        @test 0 in v
        @test any(!isfinite, v)
        @test any(x -> !iszero(x) && isinteger(x), v)
    end
end
