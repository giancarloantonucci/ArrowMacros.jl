# Tests

All tests were run in the REPL with Julia 1.6 using an Apple M1 Pro chip.

## `@↓`

```jl
using Revise
using ArrowMacros, ExtractMacro, UnPack
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
# 25.226 ns (0 allocations: 0 bytes)
@btime @unpack a = s
# 18.388 ns (0 allocations: 0 bytes)
@btime @↓ a = s
# 18.180 ns (0 allocations: 0 bytes)
```

2. Download from a vector of structs:

```jl
@btime @extract v[1] : a
# 44.910 ns (0 allocations: 0 bytes)
@btime @unpack a = v[1]
# 36.836 ns (0 allocations: 0 bytes)
@btime @↓ a = v[1]
# 37.760 ns (0 allocations: 0 bytes)
```

3. Download multiple fields:

```jl
@btime @extract s : a b
# 44.571 ns (0 allocations: 0 bytes)
@btime @unpack a, b = s
# 32.519 ns (0 allocations: 0 bytes)
@btime @↓ a, b = s
# 33.157 ns (0 allocations: 0 bytes)
```

4. Download whilst doing some maths:

```jl
@btime @extract s : a = 2a
# 48.245 ns (0 allocations: 0 bytes)
@btime @↓ a ← 2a = s
# 41.204 ns (0 allocations: 0 bytes)
```

5. Download with different names:

For some reason, `@↓ a ← b .+ 1, b = s` is not parsed correctly by `@btime`, hence the need of `f()`. On the other hand, it works fine with `@time`.

```jl
@btime @extract s : a = b .+ 1 b
# 338.470 ns (3 allocations: 160 bytes)
f() = @↓ a ← b .+ 1, b = s
@btime f()
# 320.763 ns (3 allocations: 160 bytes)
```

6. Download from nested structs:

```jl
@btime @extract s.c : d e
# 82.642 ns (0 allocations: 0 bytes)
@btime @unpack d, e = s.c
# 52.369 ns (0 allocations: 0 bytes)
@btime @↓ d, e = s.c
# 59.402 ns (0 allocations: 0 bytes)
```

## `@↑`

```jl
@↓ a, b, c = s
@↓ e, d = c
```

1. Upload a variable into a struct:

```jl
@btime @pack! s = a
# 54.822 ns (1 allocation: 16 bytes)
@btime @↑ s = a
# 21.314 ns (0 allocations: 0 bytes)
```

2. Upload into a vector of structs:

```jl
@btime @pack! v[1] = a
# 65.032 ns (1 allocation: 16 bytes)
@btime @↑ v[1] = a
# 37.215 ns (0 allocations: 0 bytes)
```

3. Upload multiple variables:

```jl
@btime @pack! s = a, b
# 70.927 ns (1 allocation: 32 bytes)
@btime @↑ s = a, b
# 34.911 ns (0 allocations: 0 bytes)
```

4. Upload into nested structs:

```jl
@btime @pack! s.c = d, e
# 91.186 ns (1 allocation: 32 bytes)
@btime @↑ s.c = d, e
# 57.264 ns (0 allocations: 0 bytes)
```
