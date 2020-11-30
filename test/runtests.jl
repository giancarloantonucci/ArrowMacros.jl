using ArrowMacros
using Test

mutable struct S1
    a
    b
end
mutable struct S2
    c
    d
end

@testset "↓" begin
    s = S1(1, [-2, -3])
    @↓ b ← abs.(b), a = s
    @test (a, b...) == (1, 2, 3)
end

@testset "⤓" begin
    es = S1(1, S2(2, [-3, -4]))
    @⤓ b ← c, a, c ← abs.(d) = es
    @test (a, b, c...) == (1, 2, 3, 4)
end

@testset "↑" begin
    s = S1(0, 0)
    a = 1
    @↑ s = b ← a + 1, a
    @test s.a == 1
    @test s.b == 2
end

@testset "⤒" begin
    s = S1(0, S2(0, 0))
    a = 1
    @⤒ s = c ← a + 1, a, d ← [3, 4]
    @test s.a == 1
    @test s.b.c == 2
    @test s.b.d == [3, 4]
end

@testset "←" begin
    f(b) = b
    @← a = f(1)
    @test a == 1
    a = [0, 2]
    function g(a, b)
        a[1] = b
        return a
    end
    @← a = g(1)
    @test a == [1, 2]
    function h!(a, b)
        a[1] = b
        return a
    end
    @← a = h(2)
    @test a == [2, 2]
end
