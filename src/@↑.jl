_pack!(composite_type, ::Val{field}, value) where {field} = setproperty!(composite_type, field, value)

function _set!(composite_type, object::Symbol)
    field = variable = object
    return quote
        $_pack!($composite_type, Val($(Expr(:quote, field))), $variable)
    end
end

function _set!(composite_type, object::Expr)
    if object.args[1] != :←
        error("`object` syntax must be like `a` or `c ← f(b)`")
    end
    field, variable_or_expression = object.args[2:3]
    dummy = gensym()
    return quote
        $dummy = $variable_or_expression
        $_pack!($composite_type, Val($(Expr(:quote, field))), $dummy)
    end
end

"""
    @↑ s = a, c ← f(b)

packs objects into mutable composite types.
"""
macro ↑(input)
    if !Meta.isexpr(input, :(=))
        error("`input` syntax must be like `s = a, c ← f(b)`")
    end
    lhs, rhs = input.args[1:2]
    composite_type = gensym()
    array_of_object = if rhs isa Symbol || (rhs isa Expr && rhs.args[1] == :←)
        [rhs]
    elseif rhs isa Expr && rhs.head == :tuple
        rhs.args
    else
        error("`rhs` syntax must be like `a, c ← f(b)`")
    end
    output = Expr(:block)
    push!(output.args, :(local $composite_type = $lhs))
    for object in array_of_object
        expression = _set!(composite_type, object)
        push!(output.args, expression)
    end
    esc(output)
end
