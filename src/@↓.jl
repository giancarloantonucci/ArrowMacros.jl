const _JULIA_CONSTANTS = (:nothing, :missing, :π, :ℯ, :im, :Inf, :NaN)

_isreserved(v::Symbol, indexing::Bool) =
    v in _JULIA_CONSTANTS || (indexing && v in (:begin, :end))

# Dotted access is not rewritten: this protects qualified names such as `Base.abs`,
# at the price of chained access
function _prepend!(ex, s; indexing=false)
    Meta.isexpr(ex, :quote) && return nothing
    indexing = indexing || Meta.isexpr(ex, :ref)
    positions = if Meta.isexpr(ex, :comparison)
        1:2:length(ex.args)  # operands at odd positions, operators at even ones
    elseif Meta.isexpr(ex, (:call, :., :macrocall, :kw))
        2:length(ex.args)  # skip the function, module, macro or keyword name
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

Unpack properties of `s` into variables. `@↓ a, b = s` binds
`a = s.a` and `b = s.b`. The arrow renames or transforms: `@↓ x ← b = s`
binds `x = s.b`, and the right of `←` may be an expression in which bare
symbols read as properties of `s`: `@↓ x ← 2a + b[1] = s` binds
`x = 2s.a + s.b[1]`.

In the expression form, function names, macro names, qualified names
(`Base.abs`) and keyword names are left alone, and so are literals, the
constants `nothing`, `missing`, `π`, `ℯ`, `im`, `Inf`, `NaN`, and `begin`/`end`
inside indexing. Other bare symbols are properties of `s`. A bare name on its
own to the right of `←` is always a property: `@↓ x ← π = s` reads `s.π`.
Chained access `a.c` is not rewritten: bind the property first. Quoted
expressions (`:(a + 1)`) are left alone. Anonymous functions and comprehensions
that introduce local names are unsupported. A name that is not a property of
`s` throws the usual error.
"""
macro ↓(input)
    Meta.isexpr(input, :(=)) || error("`$(input)` must be of form `a, b ← f(c) = s`")
    targets, source = input.args
    s = gensym()
    body = Any[:(local $s = $source)]
    for v in _entries(targets)
        name, value = v isa Symbol ? (v, v) : (v.args[2], v.args[3])
        if value isa Symbol
            push!(body, :($name = $(_fieldlookup(value, s))))
        elseif value isa Expr
            rhs = copy(value)
            _prepend!(rhs, s)
            push!(body, :($name = $rhs))
        else
            error("the right of `←` in `$(v)` must be a property name or an expression")
        end
    end
    push!(body, nothing)
    return esc(Expr(:block, body...))
end
