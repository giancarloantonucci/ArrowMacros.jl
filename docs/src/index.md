# ArrowMacros.jl

This is the documentation of [ArrowMacros.jl](https://github.com/giancarloantonucci/ArrowMacros.jl), a Julia package providing the macros `@↓` ("download": unpack struct fields into locals) and `@↑` ("upload": write locals back into struct fields).

## Installation

From the Julia REPL,

```
]add ArrowMacros
```

## Usage

```julia
using ArrowMacros
mutable struct A; a; b; end
s = A(1, [2, 3])

@↓ a, b = s              # a = s.a; b = s.b
@↓ x ← 2a + b[1] = s     # bare symbols right of ← read as fields: x = 2s.a + s.b[1]
@↑ s = a ← 10, b         # s.a = 10; s.b = b
```

Field access lowers to `Val`-specialized `getproperty`/`setproperty!`, so the sugar costs nothing at run time.

## Rewrite rules

In the expression form of `@↓`, bare symbols read as fields of `s`. The rules — pinned by the test suite:

- Function names, macro names, qualified names (`Base.abs`) and keyword names are left alone.
- Literals stay as they are; in chained comparisons (`0 < a < 2`) only the operands are rewritten.
- Chained access `a.c` is **not** rewritten — bind the field first.
- Indices follow the symbol rule: in `b[i]`, `i` must be a literal or a field.
- A name that is not a field throws the usual field error.

In `@↑`, the right of `←` is plain code — locals stay locals.

See the [API](api.md) for the full reference.
