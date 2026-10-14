"""
    _set!(s, ::Val{field}, value)

internal: `setproperty!` with the field name lifted into a `Val`; the writing
twin of `_get`.
"""
_set!(s, ::Val{field}, value) where {field} = setproperty!(s, field, value)

"""
    @↑ s = a, b ← f(c)

"upload": write local values into fields of `s`. `@↑ s = a, b` sets
`s.a = a` and `s.b = b`; the arrow form sets a field from any expression:
`@↑ s = a ← 2b` sets `s.a = 2b` with `b` a local variable. Unlike `@↓`, the
right of `←` here is plain code, not field-rewritten. Writing to a name that
is not a field of `s` throws the usual field error.
"""
macro ↑(input)
    Meta.isexpr(input, :(=)) || error("`$(input)` must be of form `s = a, b ← f(c)`")
    target, sources = input.args
    s = gensym()
    body = Any[:(local $s = $target)]
    for v in _entries(sources, "a, b ← f(c)")
        field, value = v isa Symbol ? (v, v) : (v.args[2], v.args[3])
        field isa Symbol || error("the left of `←` in `$(v)` must be a field name")
        push!(body, :($_set!($s, $(Val(field)), $value)))
    end
    push!(body, nothing)
    return esc(Expr(:block, body...))
end
