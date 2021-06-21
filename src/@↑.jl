_set!(constructor, ::Val{field}, value) where {field} = setproperty!(constructor, field, value)

"""
    @↑ s = a, c ← f(b)

inserts objects into structs' fields.
"""
macro ↑(input)
    if !Meta.isexpr(input, :(=))
        error("`$(input)` must be of form `s = a, c ← f(b)`")
    end
    input₁, input₂ = input.args[1:2]
    objects = if input₂ isa Symbol || input₂ isa Expr && input₂.args[1] == :←
        [input₂]
    elseif input₂ isa Expr && Meta.isexpr(input₂, :tuple)
        input₂.args
    else
        error("`$(input₂)` must be of form `a, c ← f(b)`")
    end
    constructor = gensym()
    output = quote
        local $constructor = $input₁
    end
    for object in objects
        if object isa Symbol
            field = value = object
            output = quote
                $output
                $_set!($constructor, $(Val(field)), $value)
            end
        elseif object isa Expr && object.args[1] == :←
            field, value = object.args[2:3]
            output = quote
                $output
                $_set!($constructor, $(Val(field)), $value)
            end
        end
    end
    esc(output)
end
