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

`@⤓` and `@⤒` work like `@↓` and `@↑`, but they search in the tree structure of `s`:

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
```

```julia
s = A(1, [2, 3])
@btime @↓ a, b = s
@btime @unpack a, b = s
@btime @extract s : a b
```

```julia
julia>
  37.429 ns (0 allocations: 0 bytes)
  37.525 ns (0 allocations: 0 bytes)
  60.720 ns (0 allocations: 0 bytes)
```

## What's next?

Current plans for future developments are:
- Improve error messages.
- Allow for `@← a .= f(b...)`
