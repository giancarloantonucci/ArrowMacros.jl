"""
    _get(s, ::Val{field})

internal: `getproperty` with the field name lifted into a `Val`, so the lookup
specializes at compile time and the macro sugar costs nothing at run time.
"""
_get(s, ::Val{field}) where {field} = getproperty(s, field)

_fieldlookup(v::Symbol, s) = :($_get($s, $(Val(v))))

"""
    _prepend!(ex, s)

internal: rewrite bare symbols inside the arrow expression `ex` into field
lookups on `s`, in place. The rules — pinned by the test suite, since four
packages downstream lean on them:

- Bare symbols become field lookups; literals stay as they are.
- The head position of calls, macro calls and dotted names is left alone:
  `f(a)` keeps `f`, `Base.abs(a)` keeps `Base.abs`.
- In chained comparisons (`0 < a < 2`) only the operands are rewritten.
- Keyword names are left alone: `round(a; digits=2)` rewrites `a` only.
- Dotted access is NOT rewritten: in `a.c`, `a` stays a local name — bind the
  field first (`@↓ tmp ← a = s`) if you need `s.a.c`. This is what protects
  qualified names, at the price of chained access.
- Indices follow the symbol rule: in `b[i]`, `i` must be a literal or a field.
"""
function _prepend!(ex, s)
    if Meta.isexpr(ex, :comparison)
        # Chained comparison: operands sit at odd indices, operators at even —
        # only the operands are field candidates.
        for i = 1:2:length(ex.args)
            v = ex.args[i]
            if v isa Symbol
                ex.args[i] = _fieldlookup(v, s)
            elseif v isa Expr
                _prepend!(v, s)
            end
        end
        return nothing
    end
    skiphead = Meta.isexpr(ex, :call) || Meta.isexpr(ex, :.) ||
               Meta.isexpr(ex, :macrocall) || Meta.isexpr(ex, :kw)
    i₀ = skiphead ? 2 : 1
    for (i, v) in enumerate(ex.args)
        if i ≥ i₀
            if v isa Symbol
                ex.args[i] = _fieldlookup(v, s)
            elseif v isa Expr
                _prepend!(v, s)
            end
        end
    end
    return nothing
end

"""
    @↓ a, b ← f(c) = s

"download": unpack fields of `s` into local variables. `@↓ a, b = s` binds
`a = s.a` and `b = s.b`. The arrow renames or transforms: `@↓ x ← b = s`
binds `x = s.b`, and the right of `←` may be an expression in which bare
symbols read as fields of `s` — `@↓ x ← 2a + b[1] = s` binds
`x = 2s.a + s.b[1]`.

In the expression form, function names, macro names, qualified names
(`Base.abs`) and keyword names are left alone; literals are untouched;
every other bare symbol is a field of `s`. Chained access `a.c` is not
rewritten — bind the field first. A name that is not a field of `s` throws
the usual field error.
"""
macro ↓(input)
    if !Meta.isexpr(input, :(=))
        error("`$(input)` must be of form `a, b ← f(c) = s`")
    end
    input₁, input₂ = input.args[1:2]
    objects = if input₁ isa Symbol || input₁ isa Expr && input₁.args[1] == :←
        [input₁]
    elseif input₁ isa Expr && Meta.isexpr(input₁, :tuple)
        input₁.args
    else
        error("`$(input₁)` must be of form `a, b ← f(c)`")
    end
    s = gensym()
    output = quote
        local $s = $input₂
    end
    for v in objects
        if v isa Symbol
            output = quote
                $output
                $v = $_get($s, $(Val(v)))
            end
        elseif v isa Expr && v.args[1] == :←
            v₁, v₂ = v.args[2:3]
            if v₂ isa Symbol
                output = quote
                    $output
                    $v₁ = $_get($s, $(Val(v₂)))
                end
            elseif v₂ isa Expr
                _prepend!(v₂, s)
                output = quote
                    $output
                    $v₁ = $v₂
                end
            end
        end
    end
    output = quote
        $output
        nothing
    end
    return esc(output)
end
