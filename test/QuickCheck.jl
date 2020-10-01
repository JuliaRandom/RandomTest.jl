@testset "QuickCheck" begin
    @quickcheck function (x::Bool, y::(-2:2), z::CloseOpen())
        @test x isa Bool
        @test y isa Int
        @test y ∈ -2:2
        @test z isa Float64
        @test 0 <= z < 1
    end
    @quickcheck function (x::(1:3)) # check with only one arg
        @test x ∈ 1:3
    end
    @quickcheck function (x::Int) # check with only one arg
        @test x isa Int
    end
end
