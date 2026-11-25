# The expression `s.v`
_fieldlookup(v::Symbol, s) = Expr(:., s, QuoteNode(v))

function _entries(ex)
    entries = Meta.isexpr(ex, :tuple) ? ex.args : Any[ex]
    for v in entries
        # `name ← value` parses as the call `←(name, value)`
        v isa Symbol ||
            (Meta.isexpr(v, :call, 3) && v.args[1] === :← && v.args[2] isa Symbol) ||
            error("`$(ex)` must be of form `a, b ← f(c)`")
    end
    return entries
end
