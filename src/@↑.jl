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
`@↑ s = a ← 2b` sets `s.a = 2b` with `b` a LOCAL variable (unlike `@↓`, the
right of `←` here is plain code, not field-rewritten). Writing to a name
that is not a field of `s` throws the usual field error.
"""
macro ↑(input)
    if !Meta.isexpr(input, :(=))
        error("`$(input)` must be of form `s = a, b ← f(c)`")
    end
    input₁, input₂ = input.args[1:2]
    vs = if input₂ isa Symbol || input₂ isa Expr && input₂.args[1] == :←
        [input₂]
    elseif input₂ isa Expr && Meta.isexpr(input₂, :tuple)
        input₂.args
    else
        error("`$(input₂)` must be of form `a, b ← f(c)`")
    end
    s = gensym()
    output = quote
        local $s = $input₁
    end
    for v in vs
        if v isa Symbol
            field = value = v
            output = quote
                $output
                $_set!($s, $(Val(field)), $value)
            end
        elseif v isa Expr && v.args[1] == :←
            field, value = v.args[2:3]
            output = quote
                $output
                $_set!($s, $(Val(field)), $value)
            end
        end
    end
    output = quote
        $output
        nothing
    end
    return esc(output)
end
