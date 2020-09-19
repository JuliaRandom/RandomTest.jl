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
