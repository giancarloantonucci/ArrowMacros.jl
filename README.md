# ArrowMacros.jl

A Julia package providing the macros `@↓`, `@↑`, `@⤓`, `@⤒`, and `@←`.

[![Build Status](https://img.shields.io/github/workflow/status/giancarloantonucci/ArrowMacros.jl/CI)](https://github.com/giancarloantonucci/ArrowMacros.jl/actions) [![Coverage](https://img.shields.io/codecov/c/github/giancarloantonucci/ArrowMacros.jl?label=coverage)](https://codecov.io/gh/giancarloantonucci/ArrowMacros.jl)

## Installation

ArrowMacros is a [registered package](https://juliahub.com/ui/Search?q=ArrowMacros&type=packages) compatible with Julia v1.0 and above. From the Julia REPL,
```julia
]add ArrowMacros
```

## Usage

```julia
using ArrowMacros
```

`@↓` and `@↑` provide [ExtractMacro.jl](https://github.com/carlobaldassi/ExtractMacro.jl)-like features with [UnPack.jl](https://github.com/mauro3/UnPack.jl)-like syntax and speed:

```julia
mutable struct A; a; b; c; end
mutable struct B; d; e; end
s = A(1, [2, 3], B(4, [5, 6])) # true
```

```julia
@↓ a, b ← b .- a = s
(a, b) == (1, [1, 2]) # true
```

```julia
a += 1
@↑ s = a, b ← (@. 2b - 1)
(s.a, s.b) == (2, [1, 3]) # true
```

`@⤓` and `@⤒` work like `@↓` and `@↑` but search in the tree structure of `s`:

```julia
@⤓ a, b ← d, c ← e[1] = s
(a, b, c) == (2, 4, 5) # true
```

```julia
@⤒ s = a ← 0, b ← 2b
(s.a, s.b) == (0, 8) # true
```

`@←` allows for a common syntax between in-place and standard functions:

```julia
f(b) = b
@← a = f(1) # same as `a = f(1)`
a == 1 # true
```

```julia
a = [0, 0]
g(a, b) = a .= b
@← a = g(0) # same as `g(a, 1)`
a == [0, 0] # true
```

```julia
h!(a, b) = a .= b
@← a = h(1) # same as `h!(a, 2)`
a == [1, 1] # true
```

## What's next?

Current plans for future developments are:
- Improve error messages.
- Allow for `@← a .= f(b...)`

## Tests

```julia
using UnPack, ExtractMacro
using BenchmarkTools
s = A(1, [2, 3], B(4, [5, 6]))
v = [s]
```

1.

```julia
julia> @btime @extract s : a
29.122 ns (0 allocations: 0 bytes)

julia> @btime @unpack a = s
18.967 ns (0 allocations: 0 bytes)

julia> @btime @↓ a = s
19.619 ns (0 allocations: 0 bytes)
```

2.

```julia
julia> @btime @extract v[1] : a
45.981 ns (0 allocations: 0 bytes)

julia> @btime @unpack a = v[1]
36.982 ns (0 allocations: 0 bytes)

julia> @btime @↓ a = v[1]
35.256 ns (0 allocations: 0 bytes)
```

3.

```julia
julia> @btime @extract s : a b
57.859 ns (0 allocations: 0 bytes)

julia> @btime @unpack a, b = s
37.299 ns (0 allocations: 0 bytes)

julia> @btime @↓ a, b = s
37.149 ns (0 allocations: 0 bytes)
```

4.

```julia
julia> @btime @extract s : a = 2a
47.218 ns (0 allocations: 0 bytes)

julia> @btime @↓ a ← 2a = s
59.135 ns (0 allocations: 0 bytes)
```

5.

```julia
julia> @btime @extract s : a = b .+ 1 b
552.968 ns (3 allocations: 160 bytes)

julia> foo() = @↓ a ← b .+ 1, b = s
julia> @btime foo()
569.386 ns (3 allocations: 160 bytes)
```

6.

```julia
julia> @btime @extract s.c : d e
115.139 ns (0 allocations: 0 bytes)

julia> @btime @unpack d, e = s.c
71.929 ns (0 allocations: 0 bytes)

julia> @btime @↓ d, e = s.c
67.673 ns (0 allocations: 0 bytes)
```

7.

```julia
julia> @btime @pack! s = a
62.497 ns (1 allocation: 16 bytes)

julia> @btime @↑ s = a
21.954 ns (0 allocations: 0 bytes)
```

8.

```julia
julia> @btime @pack! v[1] = a
80.517 ns (1 allocation: 16 bytes)

julia> @btime @↑ v[1] = a
39.042 ns (0 allocations: 0 bytes)
```

9.

```julia
julia> @btime @pack! s = a, b
93.617 ns (1 allocation: 32 bytes)

julia> @btime @↑ s = a, b
38.943 ns (0 allocations: 0 bytes)
```

10.

```julia
julia> @btime @pack! s.c = d, e
135.453 ns (1 allocation: 32 bytes)

julia> @btime @↑ s.c = d, e
70.029 ns (0 allocations: 0 bytes)
```
