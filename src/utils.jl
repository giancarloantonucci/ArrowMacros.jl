"""
    _isarrow(ex)

internal: whether `ex` is an arrow entry `name ← value`, which Julia parses as
the call `←(name, value)`.
"""
_isarrow(ex) = Meta.isexpr(ex, :call, 3) && ex.args[1] === :←

"""
    _entries(ex, form)

internal: the entries of a macro's field list `ex` — a single entry or a
tuple of them. Every entry must be a bare name or an arrow `name ← value`;
anything else raises an error naming the expected `form`, rather than being
silently dropped.
"""
function _entries(ex, form)
    entries = Meta.isexpr(ex, :tuple) ? ex.args : Any[ex]
    for v in entries
        v isa Symbol || _isarrow(v) || error("`$(ex)` must be of form `$(form)`")
    end
    return entries
end
