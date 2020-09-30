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
