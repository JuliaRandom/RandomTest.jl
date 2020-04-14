using Test, RandomTest

using RandomTest: minsize, maxsize

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

    a = rand(test(Integer), 100)
    @test length(eltype.(a)) > 3
    @test all(x -> x isa Integer, a)
end
