# ArrowMacros

A Julia package providing the macros `@↓`, `@↑`, `@⤓`, `@⤒`, and `@←`.

[![Build Status](https://github.com/antonuccig/ArrowMacros.jl/workflows/CI/badge.svg)](https://github.com/antonuccig/ArrowMacros.jl/actions)
[![Coverage](https://codecov.io/gh/antonuccig/ArrowMacros.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/antonuccig/ArrowMacros.jl)

## Usage

```julia
using ArrowMacros
```

`@↓` and `@↑` provide [`ExtractMacro`](https://github.com/carlobaldassi/ExtractMacro.jl)-like features with [`UnPack`](https://github.com/mauro3/UnPack.jl)-like syntax and speed:
```julia
mutable struct A
  a
  b
end

s = A(1, -1)
@↓ a, b ← abs(b) + 1 = s
# (a, b) == (1, 2)

a += 1
@↑ s = a, b ← 2b - 1
# (s.a, s.b) == (2, 3)
```

`@⤓` and `@⤒` work like `@↓` and `@↑`, but they search in the tree structure of the `struct`:
```julia
mutable struct B
  c
  d
end

s = A(1, B(2, [3, 4]))
@⤓ a, b ← c, c ← d[1] = s
# (a, b, c) == (1, 2, 3)

a += 1
@⤒ s = a, b ← 2b
# (s.a, s.b) == (2, 4)
```

`@←` allows for a common syntax between in-place and standard functions:
```julia
f(b) = b
@← a = f(1) # a = f(1)
# a == 1

a = [0, 0]
g(a, b) = a .= b
@← a = g(1) # g(a, 1)
# a == [1, 1]

h!(a, b) = a .= b
@← a = h(2) # h!(a, 2)
# a == [2, 2]
```

<details><summary><b>Tests</b></summary>

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

</details>

## Installation

`ArrowMacros` is compatible with Julia `v1.0` and above, and it can be installed from the REPL by running
```julia
]add ArrowMacros
```

## What's next?

Current plans for future developments are:
- Improve error messages.
- Allow for `@← a .= f(b...)`
