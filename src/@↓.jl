_unpack(composite_type, ::Val{field}) where {field} = getproperty(composite_type, field)

function _prepend(composite_type, expression::Expr)
    i₀ = Meta.isexpr(expression, :call) || Meta.isexpr(expression, :.) || Meta.isexpr(expression, :macrocall) ? 2 : 1
    for i in i₀:length(expression.args)
        dummy = expression.args[i]
        if dummy isa Symbol
            expression.args[i] = quote
                $_unpack($composite_type, Val($(Expr(:quote, dummy))))
            end
        elseif dummy isa Expr
            expression.args[i] = _prepend(composite_type, dummy)
        end
    end
    return expression
end

function _get(composite_type, object::Symbol)
    variable = field = object
    return quote
        $variable = $_unpack($composite_type, Val($(Expr(:quote, field))))
    end
end

function _get(composite_type, object::Expr)
    if object.args[1] != :←
        error("`object` syntax must be like `a` or `c ← f(b)`")
    end
    variable, field = object.args[2:3]
    if field isa Symbol
        return quote
            $variable = $_unpack($composite_type, Val($(Expr(:quote, field))))
        end
    elseif field isa Expr
        return quote
            $variable = $(_prepend(composite_type, field))
        end
    end
end

"""
    @↓ a, c ← f(b) = s

unpacks objects from composite types.
"""
macro ↓(input)
    if !Meta.isexpr(input, :(=))
        error("`input` syntax must be like `a, c ← f(b) = s`")
    end
    lhs, rhs = input.args[1:2]
    composite_type = gensym()
    array_of_objects = if lhs isa Symbol || lhs isa Expr && lhs.args[1] == :←
        [lhs]
    elseif lhs isa Expr && Meta.isexpr(lhs, :tuple)
        lhs.args
    else
        error("`lhs` syntax must be like `a, c ← f(b)`")
    end
    output = Expr(:block)
    push!(output.args, :(local $composite_type = $rhs))
    for object in array_of_objects
        expression = _get(composite_type, object)
        push!(output.args, expression)
    end
    esc(output)
end
