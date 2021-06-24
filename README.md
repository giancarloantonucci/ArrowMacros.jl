# ArrowMacros

A Julia package providing the macros `@↓`, `@↑`, `@⤓`, `@⤒`, and `@←`.

[![Build Status](https://github.com/antonuccig/ArrowMacros.jl/workflows/CI/badge.svg)](https://github.com/antonuccig/ArrowMacros.jl/actions)
[![Coverage](https://codecov.io/gh/antonuccig/ArrowMacros.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/antonuccig/ArrowMacros.jl)

## Installation

`ArrowMacros` is a registered package compatible with Julia `v1.0` and above. From the Julia REPL,
```julia
]add ArrowMacros
```

## Usage

```julia
using ArrowMacros
```

`@↓` and `@↑` provide [`ExtractMacro`](https://github.com/carlobaldassi/ExtractMacro.jl)-like features with [`UnPack`](https://github.com/mauro3/UnPack.jl)-like syntax and speed:

```julia
mutable struct A; a; b; c; end
mutable struct B; d; e; end
s = A(1, [2, 3], B(4, [5, 6]))
```

```julia
@↓ a, b ← b .- a = s
(a, b) == (1, [1, 2])
```

```julia
a += 1
@↑ s = a, b ← (@. 2b - 1)
(s.a, s.b) == (2, [1, 3])
```

`@⤓` and `@⤒` work like `@↓` and `@↑` but search in the tree structure of `s`:

```julia
@⤓ a, b ← d, c ← e[1] = s
(a, b, c) == (2, 4, 5)
```

```julia
@⤒ s = a ← 0, b ← 2b
(s.a, s.b) == (0, 8)
```

`@←` allows for a common syntax between in-place and standard functions:

```julia
f(b) = b
@← a = f(1) # same as `a = f(1)`
a == 1
```

```julia
a = [0, 0]
g(a, b) = a .= b
@← a = g(0) # same as `g(a, 1)`
a == [0, 0]
```

```julia
h!(a, b) = a .= b
@← a = h(1) # same as `h!(a, 2)`
a == [1, 1]
```

## Tests

```julia
using UnPack, ExtractMacro
using BenchmarkTools
s = A(1, [2, 3], B(4, [5, 6]))
v = [s]
```

1.

```julia
@btime @extract s : a
@btime @unpack a = s
@btime @↓ a = s
```

```julia
29.122 ns (0 allocations: 0 bytes)
18.967 ns (0 allocations: 0 bytes)
19.619 ns (0 allocations: 0 bytes)
```

2.

```julia
@btime @extract v[1] : a
@btime @unpack a = v[1]
@btime @↓ a = v[1]
```

```julia
45.981 ns (0 allocations: 0 bytes)
36.982 ns (0 allocations: 0 bytes)
35.256 ns (0 allocations: 0 bytes)
```

3.

```julia
@btime @extract s : a b
@btime @unpack a, b = s
@btime @↓ a, b = s
```

```julia
57.859 ns (0 allocations: 0 bytes)
37.299 ns (0 allocations: 0 bytes)
37.149 ns (0 allocations: 0 bytes)
```

4.

```julia
@show a == 2
@btime @extract s : a = 2a
@btime @↓ a ← 2a = s
```

```julia
47.218 ns (0 allocations: 0 bytes)
59.135 ns (0 allocations: 0 bytes)
```

5.

```julia
@btime @extract s : a = b .+ 1 b
foo() = @↓ a ← b .+ 1, b = s
@btime foo()
```

```julia
552.968 ns (3 allocations: 160 bytes)
569.386 ns (3 allocations: 160 bytes)
```

6.

```julia
@btime @extract s.c : d e
@btime @unpack d, e = s.c
@btime @↓ d, e = s.c
```

```julia
115.139 ns (0 allocations: 0 bytes)
71.929 ns (0 allocations: 0 bytes)
67.673 ns (0 allocations: 0 bytes)
```

7.

```julia
@btime @pack! s = a
@btime @↑ s = a
```

```julia
62.497 ns (1 allocation: 16 bytes)
21.954 ns (0 allocations: 0 bytes)
```

8.

```julia
@btime @pack! v[1] = a
@btime @↑ v[1] = a
```

```julia
80.517 ns (1 allocation: 16 bytes)
39.042 ns (0 allocations: 0 bytes)
```

9.

```julia
@btime @pack! s = a, b
@btime @↑ s = a, b
```

```julia
93.617 ns (1 allocation: 32 bytes)
38.943 ns (0 allocations: 0 bytes)
```

10.

```julia
@btime @pack! s.c = d, e
@btime @↑ s.c = d, e
```

```julia
135.453 ns (1 allocation: 32 bytes)
70.029 ns (0 allocations: 0 bytes)
```

## What's next?

Current plans for future developments are:
- Improve error messages.
- Allow for `@← a .= f(b...)`
