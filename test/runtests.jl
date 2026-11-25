using ArrowMacros
using Aqua
using Test

# A missing property throws FieldError from Julia 1.12 and ErrorException before it
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

    @testset "@↓" begin
        @testset "basics" begin
            s = A(1, [2, 3])

            @↓ a = s
            @test a == 1

            @↓ a, b = s
            @test (a, b) == (1, [2, 3])

            @↓ x ← b = s
            @test x == [2, 3]

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

            # The source is evaluated once
            calls = Ref(0)
            source = () -> (calls[] += 1; A(1, [2, 3]))
            @↓ a, x ← 2a = source()
            @test (a, x, calls[]) == (1, 2, 1)
        end

        @testset "rewrite rules" begin
            s = A(1.234, [2, 3])

            @↓ x ← b[1] = s
            @test x == 2                        # literal index

            @↓ x ← round(a; digits=1) = s
            @test x == 1.2                      # keyword names untouched

            @↓ x ← Base.abs(-a) = s
            @test x == 1.234                    # qualified names untouched

            @↓ x ← (a, b) = s
            @test x == (1.234, [2, 3])          # tuple of properties

            @↓ x ← (0 < a < 2) = s
            @test x === true                    # chained comparison: operands only

            @↓ x ← (a > 1 ? b : a) = s
            @test x == [2, 3]                   # ternary over properties

            @↓ x ← :(a + 1) = s
            @test x == :(a + 1)                 # quoted code untouched

            # A local index is not supported: it reads as a property and throws
            i = 1
            @test_throws NoFieldError @↓ x ← b[i] = s

            # Dotted access is not rewritten: `qqq.c` reads the undefined variable `qqq`
            @test_throws UndefVarError @↓ x ← qqq.c = s

            # Expanding `@↓` leaves the caller's expression untouched
            ex = :(@↓ x ← a + 1 = s)
            original = deepcopy(ex)
            macroexpand(@__MODULE__, ex)
            @test ex == original
        end

        @testset "constants, indexing and comparisons" begin
            s = (u=[2, 3, 5], a=2)

            @↓ x ← u[end] = s
            @test x == 5

            @↓ x ← u[(begin + 1):(end - 1)] = s
            @test x == [3]

            @↓ x ← a * π + im = s
            @test x == 2π + im

            @↓ x ← (nothing, missing, ℯ, Inf, NaN) = s
            @test isequal(x, (nothing, missing, ℯ, Inf, NaN))

            # A bare name on its own is always a property, even a constant's name
            @↓ x ← π = (π=7,)
            @test x == 7

            # Expression operands of a chained comparison are rewritten too
            @↓ x ← (0 < 2a < 5) = s
            @test x === true

            @↓ x ← (0 < 2a < 3) = s
            @test x === false

            @↓ x ← (1 < u[end] < 10) = s
            @test x === true
        end

        @testset "errors" begin
            # Malformed input is rejected when the macro expands
            @test_throws LoadError eval(:(@↓ a))             # not an assignment
            @test_throws LoadError eval(:(@↓ f(x) = s))      # malformed list
            @test_throws LoadError eval(:(@↓ (a, 1) = s))    # malformed entry in a list
            @test_throws LoadError eval(:(@↓ x ← 1 = s))     # literal right of `←`
            @test_throws LoadError eval(:(@↓ x[1] ← a = s))  # non-name left of `←`

            # A missing property is an ordinary run-time error
            s = A(1, 2)
            @test_throws NoFieldError @↓ z = s
        end
    end

    @testset "@↑" begin
        @testset "basics" begin
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

            # The target is evaluated once
            calls = Ref(0)
            t = A(0, 0)
            target = () -> (calls[] += 1; t)
            @↑ target() = a ← 1, b ← 2
            @test (t.a, t.b, calls[]) == (1, 2, 1)
        end

        @testset "errors" begin
            # Malformed input is rejected when the macro expands
            @test_throws LoadError eval(:(@↑ s))            # not an assignment
            @test_throws LoadError eval(:(@↑ s = 1))        # malformed list
            @test_throws LoadError eval(:(@↑ s = (a, 1)))   # malformed entry in a list
            @test_throws LoadError eval(:(@↑ s = a.b ← 1))  # non-name left of `←`

            # A missing property is an ordinary run-time error
            s = A(1, 2)
            @test_throws NoFieldError @↑ s = z ← 1
        end
    end
end
