# ArrowMacros

A Julia package providing the macros `@↓`, `@↑`, `@⤓`, `@⤒`, and `@←`.

[![Build Status](https://github.com/antonuccig/ArrowMacros.jl/workflows/CI/badge.svg)](https://github.com/antonuccig/ArrowMacros.jl/actions)
[![Coverage](https://codecov.io/gh/antonuccig/ArrowMacros.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/antonuccig/ArrowMacros.jl)

## Usage

```julia
using ArrowMacros
```

`@↓` and `@↑` respectively unpack and pack fields of `struct`s, merging some of the functionalities of [`UnPack`](https://github.com/mauro3/UnPack.jl) and [`ExtractMacro`](https://github.com/carlobaldassi/ExtractMacro.jl):
```julia
mutable struct S1; a; b; end
s = S1(1, -2)
@↓ a, e ← abs(b) + 1 = s
# a == 1; e == 3
```
```julia
@↑ s = a ← e, b ← 2a
# s.a == 3; s.b == 2
```

`@⤓` and `@⤒` work as `@↓` and `@↑` but search in the tree structure of the `struct`:
```julia
mutable struct S2; c; d; end
s = S1(1, S2(2, [3, 4]))
@⤓ a, b ← abs(c) + 1, c ← d[1] = s
# a == 1; b == 3; c == 3
```
```julia
@⤒ s = a ← c, b ← 2b
# s.a == 3; s.b == 6
```

`@←` allows the user to use the same syntax for both in-place and standard functions:
```julia
f(b) = b
@← a = f(1) # equiv to a = f(1)
# a == 1
```
```julia
a = [0, 0]
g(a, b) = a .= b
@← a = g(1) # equiv to g(a, 1)
# a == [1, 1]
```
```julia
h!(a, b) = a .= b
@← a = h(2) # equiv to h!(a, 2)
# a == [2, 2]
```

## Installation

`ArrowMacros` is compatible with Julia `v1.0` and above. Being not registered yet, it can be installed by cloning this repository:
```julia
]add https://github.com/antonuccig/ArrowMacros.jl
```

## What's in the pipeline

1. Fix bugs like ``@↓ a ← f .+ 1 = example``, which doesn't work. This will likely need a rewrite of the `_prepend!`s internal function.
2. Allow for ``@← a .= f(b...)``
3. Improve error messages.
