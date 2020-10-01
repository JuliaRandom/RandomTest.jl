using Test, RandomTest

using RandomTest: minsize, maxsize
using Random: MersenneTwister, gentype
using RandomExtensions: Normal, CloseOpen

using Statistics: mean

const rng = MersenneTwister()

include("scalars.jl")
include("adapters.jl")
include("test.jl")
include("QuickCheck.jl")

struct MyDist end
RandomTest.test(::MyDist) = Normal()

@testset "randt" begin
    @test randt() isa Float64
    @test randt(rng) isa Float64
    @test randt(Int) isa Int
    @test randt(rng, Int) isa Int
    d = MyDist()
    @test randt(d) isa Float64
    @test randt(rng, d) isa Float64

    @test randt(2, 3) isa Matrix{Float64}
    @test randt(rng, 2, 3) isa Matrix{Float64}
    @test randt(Int, 2, 3) isa Matrix{Int}
    @test randt(rng, Int, 2, 3) isa Matrix{Int}
    @test randt(Int, (2, 3)) isa Matrix{Int}
    @test randt(rng, Int, (2, 3)) isa Matrix{Int}
    @test randt(rng, d, 2, 3) isa Matrix{Float64}
    @test randt(d, (2, 3)) isa Matrix{Float64}
    @test randt(rng, d, (2, 3)) isa Matrix{Float64}
end

@testset "Size" begin
    @test minsize(Bool) == false
    @test maxsize(Bool) == true

    for T = Base.BitInteger_types
        @test minsize(T) == 0
        @test maxsize(T) >= 8*sizeof(T) - 1
    end
    @test maxsize(Int8) == 7
    @test maxsize(UInt8) == 8

    for T = (Int8, Int)
        m = make(T, Size(3))
        a = rand(m, 100)
        @test all(x -> -8 <= x < 8, a)
        @test any(x -> x < 0, a)
        @test any(x -> x > 0, a)
    end
    for T = (UInt8, UInt)
        m = make(T, Size(3))
        a = rand(m, 100)
        @test all(x -> x < 8, a)
        @test any(x -> x < 7, a)
        @test any(x -> x == 7, a)
    end

    @test !any(rand(make(Bool, Size(0)), 100))
    @test any(rand(make(Bool, Size(1)), 100))

    @test_throws ArgumentError rand(make(Bool, Size(2)))
    @test_throws ArgumentError rand(make(Int8, Size(8)))
    @test_throws ArgumentError rand(make(UInt8, Size(9)))
    @test_throws ArgumentError rand(make(Int64, Size(64)))
    @test_throws ArgumentError rand(make(UInt64, Size(65)))
end

@testset "Tester" begin
    for T = (Int8, Int32, Int64)
        a = rand(test(T), 1000)
        @test any(x -> x < 0, a)
        @test any(x -> x > 0, a)
        @test any(x -> x == 0, a) # fails in less than 1/100000 for Int64
        @test any(x -> x ∈ (-1, 1), a)
    end

    for T = (UInt8, UInt32, UInt64)
        a = rand(test(T), 1000)
        @test any(x -> x == 0, a)
        @test any(x -> x == 1, a)
    end

    a = rand(test(Bool), 100)
    @test any(a)
    @test !all(a)

    for T = (Integer, Signed, Unsigned, Union{Bool,Int8,UInt8,Int,UInt})
        a = rand(test(T), 100)
        @test eltype(a) == T
        @test length(eltype.(a)) > 4
        @test all(x -> x isa T, a)
    end

    # floats
    @test rand(test(Float64)) isa Float64
end

@testset "singletons" begin
    @test rand(test(Nothing)) === nothing
    @test rand(test(Missing)) === missing
end

@testset "Pair/Tuple" begin
    Ts = (Int,Integer,Bool)
    for P in Iterators.product(Ts, Ts)
        P = Pair{P...}
        @test rand(test(P)) isa P
        T = rand(Ts)
        @test rand(test(Pair{T,P})) isa Pair{T,P}
        @test rand(test(Pair{P,T})) isa Pair{P,T}

        @test rand(test(Tuple{P,Ts...})) isa Tuple{P,Ts...}
        @test rand(test(Tuple{P,Integer,P})) isa Tuple{P,Integer,P}
    end

    @test rand(test(Tuple{Ts...})) isa Tuple{Ts...}
end
