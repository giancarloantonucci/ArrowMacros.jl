# ArrowMacros.jl

A Julia package providing two macros: `@↓`, which unpacks properties into variables, and `@↑`, which writes values back into properties.

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://giancarloantonucci.github.io/ArrowMacros.jl/stable) [![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://giancarloantonucci.github.io/ArrowMacros.jl/dev) ![Build Status](https://img.shields.io/github/actions/workflow/status/giancarloantonucci/ArrowMacros.jl/CI.yml) ![Coverage Status](https://img.shields.io/codecov/c/github/giancarloantonucci/ArrowMacros.jl)

## Installation

Install from the Julia REPL (Julia 1.10 or later):

```
]add ArrowMacros
```

## Usage

The macros provide [ExtractMacro.jl](https://github.com/carlobaldassi/ExtractMacro.jl)-like features with [UnPack.jl](https://github.com/mauro3/UnPack.jl)-like syntax:

```julia
using ArrowMacros

mutable struct Point
    x::Int
    y::Int
end

p = Point(2, 5)

@↓ x, gap ← y - x = p
# x = p.x; gap = p.y - p.x
```

In `@↓`, the expression `y - x` to the right of `←` reads properties from `p`, so `gap` evaluates to `3`.

```julia
@↑ p = y ← 2 * gap
# p.y = 2 * gap
```

In `@↑`, `2 * gap` to the right of `←` is ordinary code; `gap` refers to the local variable, and `p.y` is updated to `6`.

See the [documentation](https://giancarloantonucci.github.io/ArrowMacros.jl/dev) for details.
