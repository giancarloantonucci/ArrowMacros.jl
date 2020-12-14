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
# a == 1; b == 2

a += 1
@↑ s = a, b ← 2b - 1
# s.a == 2; s.b == 3
```

`@⤓` and `@⤒` work as `@↓` and `@↑` but search in the tree structure of the `struct`:
```julia
mutable struct B
  c
  d
end

s = A(1, B(2, [3, 4]))
@⤓ a, b ← c, c ← d[1] = s
# a == 1; b == 2; c == 3

a += 1
@⤒ s = a, b ← 2b
# s.a == 2; s.b == 4
```

`@←` allows for a common syntax between in-place and standard functions:
```julia
f(b) = b
@← a = f(1) # equiv to a = f(1)

# a == 1
a = [0, 0]
g(a, b) = a .= b
@← a = g(1) # equiv to g(a, 1)
# a == [1, 1]

h!(a, b) = a .= b
@← a = h(2) # equiv to h!(a, 2)
# a == [2, 2]
```

## Installation

`ArrowMacros` is compatible with Julia `v1.0` and above, and it can be installed by running
```julia
]add ArrowMacros
```

## What's in the pipeline

1. Improve error messages?
2. Allow for `@← a .= f(b...)`
