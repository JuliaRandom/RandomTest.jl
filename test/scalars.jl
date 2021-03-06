@testset "Small" begin
    for (d, T) in (Small()              => Float64,
                   Small(33.0)          => Float64,
                   Small{Float64}(33.0) => Float64,
                   Small(Int)           => Int,
                   Small(Int, 33.0)     => Int)

        @test gentype(d) == T
        @test d.scale == 33

        v = rand(d, 1000)
        @test -5 < mean(v) < 5
        m = mean(abs.(v))
        @test 29 < m < 37
        @test maximum(sort(abs.(v))[1:end-50]) < 103

        w = rand(scale(0.5, d), 1000)
        @test 29/2 < mean(abs.(w)) < 37/2

        v = rand(d, 20000)
        @test -1.3 < mean(v) < 1.3
        m = mean(abs.(v))
        @test 32 < m < 34
        @test maximum(sort(abs.(v))[1:end-1000]) < 103
    end

    d = Small(BigInt, 1000)
    @test d.scale == 1000

    v = rand(d, 1000)
    @test eltype(v) == BigInt

    m = mean(abs.(v))
    @test 878 < m < 1122

    # overflow
    d = Small(Int8, 100)
    @test rand(d, 1000) isa Vector{Int8} # must not error out
end

@testset "Nat" begin
    for d in (Nat(), Nat(Int), Nat(33.0), Nat(Int, 33.0))
        @test d isa Abs{Int64,Small{Int64}}

        v = rand(d, 1000)
        @test 29 < mean(abs.(v)) < 37
        w = rand(scale(0.5, d), 1000)
        @test 29/2 < mean(abs.(w)) < 37/2
    end
end
