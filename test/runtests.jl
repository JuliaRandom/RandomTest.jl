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
