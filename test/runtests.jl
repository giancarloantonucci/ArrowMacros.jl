using ArrowMacros
using Test

mutable struct A
    a
    b
end

mutable struct B
    c
    d
end

@testset "↓" begin
    s = A(1, [2, 3])
    @↓ a = s
    @test a == 1

    @↓ a, b = s
    @test (a, b) == (1, [2, 3])

    @↓ a ← b .+ 2 = s
    @test a == [4, 5]

    @↓ a ← 2a, b = s
    @test (a, b) == (2, [2, 3])

    @↓ c ← (@. abs(3a + 2b)) = s
    @test c == [7, 9]

    s = A(1, B(2, [3, 4]))
    @↓ c, d = s.b
    @test (c, d) == (2, [3, 4])

    v = [A(1, [2, 3])]
    @↓ a, b = v[1]
    @test (a, b) == (1, [2, 3])
end

@testset "↑" begin
    a = 1
    s = A(0, 0)
    @↑ s = a
    @test s.a == 1

    b = [2, 3]
    @↑ s = a, b
    @test (s.a, s.b) == (1, [2, 3])

    @↑ s = a ← b .+ 2
    @test s.a == [4, 5]

    @↑ s = a ← 2a, b
    @test (s.a, s.b) == (2, [2, 3])

    @↑ s = b ← (@. abs(3a + 2b))
    @test s.b == [7, 9]

    s.b = B(0, 0)
    @↑ s.b = c ← 2, d ← [3, 4]
    @test (s.b.c, s.b.d) == (2, [3, 4])

    v = [s]
    @↑ v[1] = a ← 2, b ← [3, 4]
    @test (v[1].a, v[1].b) == (2, [3, 4])
end
