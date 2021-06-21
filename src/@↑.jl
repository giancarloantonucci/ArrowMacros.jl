_set!(s, ::Val{field}, value) where {field} = setproperty!(s, field, value)

"""
    @↑ s = a, c ← f(b)

inserts vs into structs' fields.
"""
macro ↑(input)
    if !Meta.isexpr(input, :(=))
        error("`$(input)` must be of form `s = a, c ← f(b)`")
    end
    input₁, input₂ = input.args[1:2]
    vs = if input₂ isa Symbol || input₂ isa Expr && input₂.args[1] == :←
        [input₂]
    elseif input₂ isa Expr && Meta.isexpr(input₂, :tuple)
        input₂.args
    else
        error("`$(input₂)` must be of form `a, c ← f(b)`")
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
    end |> esc
end
