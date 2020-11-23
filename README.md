# ArrowMacros

A Julia package providing the macros `@↓`, `@↑`, and `@←`.

[![Build Status](https://github.com/antonuccig/ArrowMacros.jl/workflows/CI/badge.svg)](https://github.com/antonuccig/ArrowMacros.jl/actions)
[![Coverage](https://codecov.io/gh/antonuccig/ArrowMacros.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/antonuccig/ArrowMacros.jl)

## Description

Some simple macros to:

- unpack (`@↓`) and pack (`@↑`) (manipulated) fields and **sub-fields** of `struct`s:
```julia
mutable struct Example; a; b; end
mutable struct Example2; c; d; end
example = Example(1, Example2(2, [3, 4]))
```
```julia
using ArrowMacros
@↓ a, b ← abs(c) + 1, c ← d[1] = example
# a == 1; b == 3; c == 3
```
```julia
@↑ example = a ← c, b ← 2b
# example.a == 3; example.b == 6
```

- use the same syntax for both in-place and standard functions (`@←`):
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

`ArrowMacros` is compatible with Julia `v1.0` and above; it can be installed by cloning this repository:
```julia
]add https://github.com/antonuccig/ArrowMacros.jl
```

## What's in the pipeline

1. Fix bugs like
```julia
@↓ a ← f .+ 1 = example # doesn't work
```
which will likely need a rewrite of the `_prepend!` internal function.

2. Allow for
```julia
@← a .= f(b...)
```

3. Improve error messages.
