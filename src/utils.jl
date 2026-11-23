# The entries of a macro's list `ex`: a single entry or a tuple of them. Each must be
# a bare name or an arrow `name ← value` (parsed as the call `←(name, value)`);
# anything else is an error rather than being silently dropped.
function _entries(ex)
    entries = Meta.isexpr(ex, :tuple) ? ex.args : Any[ex]
    for v in entries
        v isa Symbol ||
            (Meta.isexpr(v, :call, 3) && v.args[1] === :←) ||
            error("`$(ex)` must be of form `a, b ← f(c)`")
    end
    return entries
end
