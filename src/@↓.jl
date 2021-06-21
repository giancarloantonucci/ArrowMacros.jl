_get(constructor, ::Val{field}) where {field} = getproperty(constructor, field)
_check(constructor, ::Val{field}) where {field} = field in typeof(constructor).name.names

function _prepend!(expression, constructor)
    _iscall = Meta.isexpr(expression, :call)
    _isdot = Meta.isexpr(expression, :.)
    _ismacrocall = Meta.isexpr(expression, :macrocall)
    i₀ = _iscall || _isdot || _ismacrocall ? 2 : 1
    for (i, object) in enumerate(expression.args)
        if i ≥ i₀
            if object isa Symbol
                obj_ = string(object)
                expression.args[i] = quote
                    if $_check($constructor, $(Val(object)))
                        $_get($constructor, $(Val(object)))
                    else
                        $object
                    end
                end
            elseif object isa Expr
                _prepend!(object, constructor)
            end
        end
    end
end

"""
    @↓ a, c ← f(b) = s

extracts fields from structs.
"""
macro ↓(input)
    if !Meta.isexpr(input, :(=))
        error("`$(input)` must be of form `a, c ← f(b) = s`")
    end
    input₁, input₂ = input.args[1:2]
    objects = if input₁ isa Symbol || input₁ isa Expr && input₁.args[1] == :←
        [input₁]
    elseif input₁ isa Expr && Meta.isexpr(input₁, :tuple)
        input₁.args
    else
        error("`$(input₁)` must be of form `a, c ← f(b)`")
    end
    constructor = gensym()
    output = quote
        local $constructor = $input₂
    end
    for object in objects
        if object isa Symbol
            output = quote
                $output
                $object = $_get($constructor, $(Val(object)))
            end
        elseif object isa Expr && object.args[1] == :←
            object₁, object₂ = object.args[2:3]
            if object₂ isa Symbol
                output = quote
                    $output
                    $(object₁) = $_get($constructor, $(Val(object₂)))
                end
            elseif object₂ isa Expr
                _prepend!(object₂, constructor)
                output = quote
                    $output
                    $(object₁) = $(object₂)
                end
            end
        end
    end
    esc(output)
end
