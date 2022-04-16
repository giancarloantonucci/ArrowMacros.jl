# Tests

## `@↓`

```jl
using Revise
using ArrowMacros, DownloadMacro, UnPack
using BenchmarkTools
```

```jl
BenchmarkTools.DEFAULT_PARAMETERS.samples = 1_000_000
mutable struct A; a; b; c; end
mutable struct B; d; e; end
s = A(1, [2, 3], B(4, [5, 6]))
v = [s]
```

1. Download a field from a struct:

```jl
@btime @extract s : a
# 27.797 ns (0 allocations: 0 bytes)
@btime @unpack a = s
# 18.437 ns (0 allocations: 0 bytes)
@btime @↓ a = s
# 18.428 ns (0 allocations: 0 bytes)
```

2. Download from a vector of structs:

```jl
@btime @extract v[1] : a
# 49.558 ns (0 allocations: 0 bytes)
@btime @unpack a = v[1]
# 36.833 ns (0 allocations: 0 bytes)
@btime @↓ a = v[1]
# 34.892 ns (0 allocations: 0 bytes)
```

3. Download multiple fields:

```jl
@btime @extract s : a b
# 51.711 ns (0 allocations: 0 bytes)
@btime @unpack a, b = s
# 35.136 ns (0 allocations: 0 bytes)
@btime @↓ a, b = s
# 35.544 ns (0 allocations: 0 bytes)
```

4. Download whilst doing some maths:

```jl
@btime @extract s : a = 2a
# 45.942 ns (0 allocations: 0 bytes)
@btime @↓ a ← 2a = s
# 35.529 ns (0 allocations: 0 bytes)
```

5. Download with different names:

For some reason, `@↓ a ← b .+ 1, b = s` is not parsed correctly by `@btime`, hence the need of `f()`. On the other hand, it works fine with `@time`.

```jl
@btime @extract s : a = b .+ 1 b
# 435.237 ns (3 allocations: 144 bytes)
f() = @↓ a ← b .+ 1, b = s
@btime f()
# 417.050 ns (3 allocations: 144 bytes)
```

6. Download from nested structs:

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

1. Upload a variable into a struct:

```jl
@btime @pack! s = a
# 176.963 ns (1 allocation: 16 bytes)
@btime @↑ s = a
# 24.577 ns (0 allocations: 0 bytes)
```

2. Upload into a vector of structs:

```jl
@btime @pack! v[1] = a
# 194.824 ns (1 allocation: 16 bytes)
@btime @↑ v[1] = a
# 39.872 ns (0 allocations: 0 bytes)
```

3. Upload multiple variables:

```jl
@btime @pack! s = a, b
# 226.328 ns (1 allocation: 32 bytes)
@btime @↑ s = a, b
# 44.901 ns (0 allocations: 0 bytes)
```

4. Upload into nested structs:

```jl
@btime @pack! s.c = d, e
# 272.644 ns (1 allocation: 32 bytes)
@btime @↑ s.c = d, e
# 70.399 ns (0 allocations: 0 bytes)
```
