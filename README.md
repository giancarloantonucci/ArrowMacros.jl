# ArrowMacros.jl

A Julia package providing the macros `@↓` and `@↑`.

[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://giancarloantonucci.github.io/ArrowMacros.jl/dev) ![Build Status](https://img.shields.io/github/actions/workflow/status/giancarloantonucci/ArrowMacros.jl/CI.yml) ![Coverage Status](https://img.shields.io/codecov/c/github/giancarloantonucci/ArrowMacros.jl)

## Installation

ArrowMacros is a [registered package](https://juliahub.com/ui/Search?q=ArrowMacros&type=packages) compatible with Julia v1.6 and above. From the Julia REPL,

```
]add ArrowMacros
```

## Usage

`@↓` and `@↑` provide [ExtractMacro.jl](https://github.com/carlobaldassi/ExtractMacro.jl)-like features with [UnPack.jl](https://github.com/mauro3/UnPack.jl)-like syntax and speed. For example,

```julia
using ArrowMacros
mutable struct A; a; b; c; end
mutable struct B; d; e; end
s = A(1, [2, 3], B(4, [5, 6]))

@↓ a, b ← b .- a = s
# (a, b) == (1, [1, 2])

a += 1
@↑ s = a, b ← (@. 2b - 1)
# (s.a, s.b) == (2, [1, 3])
```

Field access lowers to `Val`-specialized `getproperty`/`setproperty!`, so the sugar costs nothing at run time.

### Rewrite rules

In the expression form of `@↓` (right of `←`), bare symbols read as fields of `s`. The rules, pinned by the test suite:

- Function names, macro names, qualified names (`Base.abs`) and keyword names are left alone: `@↓ x ← round(a; digits=2) = s` rewrites `a` only.
- Literals stay as they are; in chained comparisons (`0 < a < 2`) only the operands are rewritten.
- Chained field access `a.c` is **not** rewritten — bind the field first: `@↓ tmp ← a = s`, then `tmp.c`.
- Indices follow the symbol rule: in `b[i]`, `i` must be a literal or a field of `s`.
- A name that is not a field of `s` throws the usual field error.

In `@↑`, the right of `←` is plain code — locals stay locals.

Read the [documentation](https://giancarloantonucci.github.io/ArrowMacros.jl/dev) for a complete overview of this package.
