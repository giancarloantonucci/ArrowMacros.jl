"""
    @↑ s = a, b ← f(c)

Write values to properties of `s`. `@↑ s = a, b` sets `s.a = a` and
`s.b = b`. The right of `←` is ordinary code in the caller's scope, not rewritten
as in `@↓`: `@↑ s = a ← 2b` sets `s.a = 2b`, with `b` the local variable.
"""
macro ↑(input)
    Meta.isexpr(input, :(=)) || error("`$(input)` must be of form `s = a, b ← f(c)`")
    target, sources = input.args
    # `f(x) = a, b` parses as a short function definition, which wraps the right in a block
    Meta.isexpr(sources, :block) && (sources = sources.args[end])
    s = gensym()
    body = Any[:(local $s = $target)]
    for v in _entries(sources)
        field, value = v isa Symbol ? (v, v) : (v.args[2], v.args[3])
        push!(body, :($(_fieldlookup(field, s)) = $value))
    end
    push!(body, nothing)
    return esc(Expr(:block, body...))
end
