"""
    _get(s, ::Val{field})

internal: `getproperty` with the field name lifted into a `Val`, so the lookup
specializes at compile time and the macro sugar costs nothing at run time.
"""
_get(s, ::Val{field}) where {field} = getproperty(s, field)

_fieldlookup(v::Symbol, s) = :($_get($s, $(Val(v))))

# Names that keep their Julia meaning in the expression form of `@↓`.
const _CONSTANTS = (:nothing, :missing, :π, :ℯ, :im, :Inf, :NaN)

_isreserved(v::Symbol, indexing::Bool) = v in _CONSTANTS || (indexing && v in (:begin, :end))

"""
    _prepend!(ex, s; indexing=false)

internal: rewrite bare symbols inside the arrow expression `ex` into field
lookups on `s`, in place. `indexing` records whether `ex` sits inside an
indexing expression. The rules, pinned by the test suite because the NSDE
packages rely on them:

- Bare symbols become field lookups; literals stay as they are.
- Constants `nothing`, `missing`, `π`, `ℯ`, `im`, `Inf`, `NaN` are left alone.
- Inside indexing expressions, `begin` and `end` keep their Julia meaning.
- The head position of calls, macro calls and dotted names is left alone:
  `f(a)` keeps `f`, `Base.abs(a)` keeps `Base.abs`.
- In chained comparisons (`0 < a < 2`) only the operands are rewritten.
- Keyword names are left alone: `round(a; digits=2)` rewrites `a` only.
- Dotted access is not rewritten: in `a.c`, `a` stays a local name. Bind the
  field first (`@↓ tmp ← a = s`) if you need `s.a.c`. This is what protects
  qualified names, at the price of chained access.
- Indices follow the symbol rule: in `b[i]`, `i` must be a literal or a field.
- Names bound inside the expression, such as anonymous-function arguments
  and comprehension variables, are rewritten too, so such expressions are
  not supported.
"""
function _prepend!(ex, s; indexing=false)
    indexing = indexing || Meta.isexpr(ex, :ref)
    positions = if Meta.isexpr(ex, :comparison)
        1:2:length(ex.args) # operands at odd positions, operators at even ones
    elseif Meta.isexpr(ex, (:call, :., :macrocall, :kw))
        2:length(ex.args) # skip the function, module, macro or keyword name
    else
        1:length(ex.args)
    end
    for i in positions
        v = ex.args[i]
        if v isa Symbol && !_isreserved(v, indexing)
            ex.args[i] = _fieldlookup(v, s)
        elseif v isa Expr
            _prepend!(v, s; indexing)
        end
    end
    return nothing
end

"""
    @↓ a, b ← f(c) = s

"download": unpack fields of `s` into local variables. `@↓ a, b = s` binds
`a = s.a` and `b = s.b`. The arrow renames or transforms: `@↓ x ← b = s`
binds `x = s.b`, and the right of `←` may be an expression in which bare
symbols read as fields of `s`: `@↓ x ← 2a + b[1] = s` binds
`x = 2s.a + s.b[1]`.

In the expression form, function names, macro names, qualified names
(`Base.abs`) and keyword names are left alone, and so are literals, the
constants `nothing`, `missing`, `π`, `ℯ`, `im`, `Inf`, `NaN`, and `begin`/`end`
inside indexing. Other bare symbols are fields of `s`. Chained access `a.c` is
not rewritten: bind the field first. A name that is not a field of `s` throws
the usual field error.
"""
macro ↓(input)
    Meta.isexpr(input, :(=)) || error("`$(input)` must be of form `a, b ← f(c) = s`")
    targets, source = input.args
    s = gensym()
    body = Any[:(local $s = $source)]
    for v in _entries(targets, "a, b ← f(c)")
        if v isa Symbol
            push!(body, :($v = $(_fieldlookup(v, s))))
            continue
        end
        name, value = v.args[2], v.args[3]
        if value isa Symbol
            push!(body, :($name = $(_fieldlookup(value, s))))
        elseif value isa Expr
            _prepend!(value, s)
            push!(body, :($name = $value))
        else
            error("the right of `←` in `$(v)` must be a field name or an expression")
        end
    end
    push!(body, nothing)
    return esc(Expr(:block, body...))
end
