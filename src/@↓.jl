_get(s, ::Val{field}) where {field} = getproperty(s, field)
_check(s, ::Val{field}) where {field} = field in typeof(s).name.names

function _prepend!(ex, s)
    _iscall = Meta.isexpr(ex, :call)
    _isdot = Meta.isexpr(ex, :.)
    _ismacrocall = Meta.isexpr(ex, :macrocall)
    i₀ = _iscall || _isdot || _ismacrocall ? 2 : 1
    for (i, v) in enumerate(ex.args)
        if i ≥ i₀
            if v isa Symbol
                obj_ = string(v)
                ex.args[i] = quote
                    if $_check($s, $(Val(v)))
                        $_get($s, $(Val(v)))
                    else
                        $v
                    end
                end
            elseif v isa Expr
                _prepend!(v, s)
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
    s = gensym()
    output = quote
        local $s = $input₂
    end
    for v in objects
        if v isa Symbol
            output = quote
                $output
                $v = $_get($s, $(Val(v)))
            end
        elseif v isa Expr && v.args[1] == :←
            v₁, v₂ = v.args[2:3]
            if v₂ isa Symbol
                output = quote
                    $output
                    $v₁ = $_get($s, $(Val(v₂)))
                end
            elseif v₂ isa Expr
                _prepend!(v₂, s)
                output = quote
                    $output
                    $v₁ = $v₂
                end
            end
        end
    end
    esc(output)
end
