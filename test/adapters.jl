@testset "Sized" begin
    d = Sized{Int}(1:5) do sz
        make(Int, Size(sz))
    end
    @test gentype(d) == Int
    @test rand(d) isa Int
    @test all(∈(-32:31), rand(d, 100))

    d = Sized{Vector{Int}}(1:5) do sz
        make(Vector, 1:sz, sz)
    end
    @test gentype(d) == Vector{Int}
    @test rand(d) isa Vector{Int}
    @test all(rand(rng, d, 100)) do v
        length(v) ∈ 1:5
        all(∈(1:5), v)
    end

    # with return_type inference
    d = Sized((1, 2, 3)) do sz
        sz:sz
    end
    @test gentype(d) == Int
    @test rand(d) ∈ 1:3
end

@testset "Staged" begin
    for d in (Staged{Vector{Int}}(sz -> make(Vector, 1:sz, sz), 1:9),
              Staged(sz -> make(Vector, 1:sz, sz), 1:9))
        @test gentype(d) == Vector{Int}
        v = rand(d)
        @test length(v) ∈ 1:9
        @test all(∈(1:9), v)
    end

    d = Staged((Int, UInt, Bool)) do T
        make(Vector, T, 3)
    end
    # we don't test gentype(d), it's too hard on the compiler
    v = rand(d, 10)
    @test all(x -> x isa Vector, v)
    es =  Set(eltype.(v))
    @test length(es) > 1
    @test es ⊆ [Int, UInt, Bool]
end

@testset "Stacked" begin
    for d in (Stacked{Vector{Int}}(d -> make(Vector, d, rand(d)), 1:9),
              Stacked(d -> make(Vector, d, rand(d)), 1:9))
        # TODO: replace rand(d) above by d when RandomExtensions supports it
        @test gentype(d) <: Vector
        v = rand(d)
        @test length(v) ∈ 1:9
        @test all(∈(1:9), v)
    end

    d = Stacked((Int, UInt, Bool)) do Ts
        make(Vector, Ts, 3)
    end
    # we don't test gentype(d), it's too hard on the compiler
    v = rand(d, 10)
    @test all(x -> x isa Vector{DataType}, v)
end

@testset "Abs" begin
    d = Abs(Int8)
    @test gentype(d) == Int8
    @test extrema(rand(d, 10000)) == (0, 127) # checks that abs(typemin(Int8)) is handled

    d = Abs(Normal())
    @test gentype(d) == Float64
    @test all(x -> x >= 0, rand(d, 10000))

    d = Abs((-1, 3))
    @test gentype(d) == Int
    @test all(∈((1, 3)), rand(d, 100))
end

@testset "Frequency" begin
    for d in (Frequency(9 => 1:9, 1 => 10:99),
              Frequency{Int}(9 => 1:9, 1 => 10:99),
              Frequency((9 => 1:9, 1 => 10:99)),
              Frequency{Int}((9 => 1:9, 1 => 10:99)),
              Frequency([9 => 1:9, 1 => 10:99]),
              Frequency{Int}([9 => 1:9, 1 => 10:99]))

              @test gentype(d) == Int
              @test rand(d) ∈ 1:99
              @test 8850 < count(∈(1:9), rand(d, 10000)) < 9150
    end
end

@testset "AdHoc" begin
    for d in (AdHoc() do rng
                  rand(rng, Bool) ? rand(rng, 1:3) : 4
              end,
              AdHoc{Int}() do rng
                  rand(rng, Bool) ? rand(rng, 1:3) : 4
              end)

        @test gentype(d) == Int
        all(∈(1:4), rand(d, 1000))
    end
end
