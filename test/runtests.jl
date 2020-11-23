using ArrowMacros
using Test

mutable struct Example
    a
    b
end
mutable struct Example2
    c
    d
end
mutable struct Example3
    e
    f
end

@testset "↓" begin
    example = Example(1, Example2(2, Example3(3, [-4, -5])))
    @↓ a, c, d ← e, e ← abs.(f) = example
    @test (a, c, d, e...) == (1, 2, 3, 4, 5)
end

@testset "↑" begin
    example = Example(0, Example2(0, Example3(0, 0)))
    a = 4
    @↑ example = a, c ← abs(-3), d ← Example3(2, 1)
    @test example.a == 4
    @test example.b.c == 3
    @test example.b.d.e == 2
    @test example.b.d.f == 1
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
