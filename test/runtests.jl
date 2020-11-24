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
    @↓ a, b ← abs.(b) = s
    @test (a, b...) == (1, 2, 3)
end

@testset "⤓" begin
    es = S1(1, S2(2, [-3, -4]))
    @⤓ a, b ← c, c ← abs.(d) = es
    @test (a, b, c...) == (1, 2, 3, 4)
end

@testset "↑" begin
    s = S1(0, 0)
    a = 1
    @↑ s = a, b ← a + 1
    @test s.a == 1
    @test s.b == 2
end

@testset "⤒" begin
    s = S1(0, S2(0, 0))
    a = 1
    @⤒ s = a, c ← a + 1, d ← [3, 4]
    @test s.a == 1
    @test s.b.c == 2
    @test s.b.d == [3, 4]
end

@testset "←" begin
    f(b) = b
    @← a = f(1)
    @test a == 1
    a = [0, 2]
    g(a, b) = a[1] = b
    @← a = g(1)
    @test a == [1, 2]
    h!(a, b) = a[1] = b
    @← a = h(2)
    @test a == [2, 2]
end
