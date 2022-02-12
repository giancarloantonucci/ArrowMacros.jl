# Tests

## `@↓`

```jl
using Revise, ArrowMacros, ExtractMacro, UnPack, BenchmarkTools
BenchmarkTools.DEFAULT_PARAMETERS.samples = 1_000_000
mutable struct A; a; b; c; end
mutable struct B; d; e; end
s = A(1, [2, 3], B(4, [5, 6]))
v = [s]
```

1. Extract a field from a struct:

```jl
@btime @extract s : a
# 27.797 ns (0 allocations: 0 bytes)
@btime @unpack a = s
# 18.437 ns (0 allocations: 0 bytes)
@btime @↓ a = s
# 18.428 ns (0 allocations: 0 bytes)
```

2. Extract a field from a vector of structs:

```jl
@btime @extract v[1] : a
# 49.558 ns (0 allocations: 0 bytes)
@btime @unpack a = v[1]
# 36.833 ns (0 allocations: 0 bytes)
@btime @↓ a = v[1]
# 34.892 ns (0 allocations: 0 bytes)
```

3. Extract more than one fields from a struct:

```jl
@btime @extract s : a b
# 51.711 ns (0 allocations: 0 bytes)
@btime @unpack a, b = s
# 35.136 ns (0 allocations: 0 bytes)
@btime @↓ a, b = s
# 35.544 ns (0 allocations: 0 bytes)
```

4. Extract whilst doing some maths:

```jl
@btime @extract s : a = 2a
# 45.942 ns (0 allocations: 0 bytes)
@btime @↓ a ← 2a = s
# 35.529 ns (0 allocations: 0 bytes)
```

5. Extract into differently named variables:

Note that there is an issue between `ArrowMacros` and `BenchmarkTools` for which the expression below is not parsed correctly. On the other hand, the same expression works just fine with `@time`.

```jl
@btime @extract s : a = b .+ 1 b
# 435.237 ns (3 allocations: 144 bytes)
f() = @↓ a ← b .+ 1, b = s
@btime f()
# 417.050 ns (3 allocations: 144 bytes)
```

6. Extract from nested structs:

```jl
@btime @extract s.c : d e
# 111.674 ns (0 allocations: 0 bytes)
@btime @unpack d, e = s.c
# 64.945 ns (0 allocations: 0 bytes)
@btime @↓ d, e = s.c
# 62.787 ns (0 allocations: 0 bytes)
```

## `@↑`

```jl
@↓ a, b, c = s
@↓ e, d = c
```

1. Insert a variable into a struct:

```jl
@btime @pack! s = a
# 176.963 ns (1 allocation: 16 bytes)
@btime @↑ s = a
# 24.577 ns (0 allocations: 0 bytes)
```

2. Insert a variable into a vector of structs:

```jl
@btime @pack! v[1] = a
# 194.824 ns (1 allocation: 16 bytes)
@btime @↑ v[1] = a
# 39.872 ns (0 allocations: 0 bytes)
```

3. Insert more than one variables into a struct:

```jl
@btime @pack! s = a, b
# 226.328 ns (1 allocation: 32 bytes)
@btime @↑ s = a, b
# 44.901 ns (0 allocations: 0 bytes)
```

4. Insert into nested structs:

```jl
@btime @pack! s.c = d, e
# 272.644 ns (1 allocation: 32 bytes)
@btime @↑ s.c = d, e
# 70.399 ns (0 allocations: 0 bytes)
```

## `@←`

1. Leave the expression unchanged:

```jl
f(x) = x
@btime a = f(2)
# 0.027 ns (0 allocations: 0 bytes)
@btime @← a = f(3)
a
# 0.027 ns (0 allocations: 0 bytes)
```

2. Switch to in-place syntax:

Some overhead is present due to `f! = Symbol(f, "!")`, as shown below:

```jl
a = 0
p!(a, b) = a = b
@btime p!(a, 1)
# 0.027 ns (0 allocations: 0 bytes)
@btime @← a = p(1)
# 86.807 ns (0 allocations: 0 bytes)
```

However, this overhead becomes negligible for big-enough problems:

```jl
a = zeros(1000);
p!(a, b) = a .= b
@btime p!(a, 1)
# 102.673 ns (0 allocations: 0 bytes)
@btime @← a = p(1)
# 92.511 ns (0 allocations: 0 bytes)
```
