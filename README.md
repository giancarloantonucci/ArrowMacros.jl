# ArrowMacros.jl

A Julia package providing the macros `@↓`, `@↑`, `@⤓`, `@⤒`, and `@←`.

[![Docs Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://giancarloantonucci.github.io/ArrowMacros.jl/stable) [![Docs Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://giancarloantonucci.github.io/ArrowMacros.jl/dev) [![Build Status](https://img.shields.io/github/workflow/status/giancarloantonucci/ArrowMacros.jl/CI)](https://github.com/giancarloantonucci/ArrowMacros.jl/actions) [![Coverage](https://img.shields.io/codecov/c/github/giancarloantonucci/ArrowMacros.jl?label=coverage)](https://codecov.io/gh/giancarloantonucci/ArrowMacros.jl)

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
