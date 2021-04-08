function _deep_pack!(composite_type, ::Val{field}, value, lvl=0) where {field}
    if isdefined(composite_type, field)
        return setproperty!(composite_type, field, value)
    else
        for propertyname in propertynames(composite_type)
            sub_composite_type = getproperty(composite_type, propertyname)
            if isstructtype(typeof(sub_composite_type))
                _deep_pack!(sub_composite_type, Val(field), value, lvl+1)
            end
        end
    end
end

function _deep_set!(composite_type, object::Symbol)
    field = variable = object
    return quote
        $_deep_pack!($composite_type, Val($(Expr(:quote, field))), $variable)
    end
end

function _deep_set!(composite_type, object::Expr)
    if object.args[1] != :←
        error("`object` syntax must be like `a` or `c ← f(b)`")
    end
    field, variable_or_expression = object.args[2:3]
    tmp = gensym()
    return quote
        $tmp = $variable_or_expression
        $_deep_pack!($composite_type, Val($(Expr(:quote, field))), $tmp)
    end
end

"""
    @⤒ s = a, c ← f(b)

packs objects into mutable composite types or subfields.
"""
macro ⤒(input)
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
        expression = _deep_set!(composite_type, object)
        push!(output.args, expression)
    end
    esc(output)
end
