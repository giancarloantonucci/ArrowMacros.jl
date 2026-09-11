using ArrowMacros
using Test
using Aqua

# Julia 1.12 reports a missing field as FieldError; older versions as
# ErrorException — cover both.
const NoFieldError = isdefined(Base, :FieldError) ? Base.FieldError : ErrorException

mutable struct A
    a
    b
end

mutable struct B
    c
    d
end

@testset "ArrowMacros" begin

@testset "Aqua" begin
    Aqua.test_all(ArrowMacros)
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

@testset "expression rewrite rules (pinned semantics)" begin
    s = A(1.234, [2, 3])

    @↓ x ← b[1] = s
    @test x == 2                        # literal index works

    @↓ x ← round(a; digits=1) = s
    @test x == 1.2                      # keyword NAMES untouched (head :kw — fixed, used to error)

    @↓ x ← Base.abs(-a) = s
    @test x == 1.234                    # qualified call names untouched

    @↓ x ← (a, b) = s
    @test x == (1.234, [2, 3])          # tuple of fields

    @↓ x ← (0 < a < 2) = s
    @test x === true                    # chained comparison (head :comparison — fixed, used to error)

    @↓ x ← (a > 1 ? b : a) = s
    @test x == [2, 3]                   # ternary over fields

    i = 1
    @test_throws NoFieldError @↓ x ← b[i] = s
    # a local index is NOT supported: it reads as a field and throws loudly

    # Dotted access is not rewritten — `qqq` stays a local name (here absent):
    @test_throws UndefVarError eval(:(@↓ x ← qqq.c = A(1, B(2, 3))))
end

@testset "error paths" begin
    @test_throws LoadError eval(:(@↓ a))       # not an assignment
    @test_throws LoadError eval(:(@↓ f(x) = s))  # malformed unpack list
    @test_throws LoadError eval(:(@↑ s))       # not an assignment
    @test_throws LoadError eval(:(@↑ s = 1))   # malformed field list

    s = A(1, 2)
    @test_throws NoFieldError @↓ z = s         # missing field names itself in the error
    @test_throws NoFieldError @↑ s = z ← 1
end

end # outer testset
