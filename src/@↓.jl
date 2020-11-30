function _getfield(s, b)
    if isstructtype(typeof(s))
        if isdefined(s, b)
            return getfield(s, b)
        end
    end
    return b
end

function _prepend!(ex, s)
    for (i, ex_i) in enumerate(ex.args)
        if ex_i isa Symbol
            ex_i_string = string(ex_i)
            t = gensym()
            ex.args[i] = quote
                $t = $_getfield($s, Symbol($ex_i_string))
                if $t isa Symbol
                    $t = $ex_i
                end
                $t
            end
        elseif ex_i isa Expr
            ex.args[i] = _prepend!(ex_i, s)
        end
    end
    return ex
end

get_expr(str, obj::Symbol) = :($obj = $str.$obj)
function get_expr(str, obj::Expr)
    if obj.args[1] == :←
        a, b = obj.args[2:3]
        e = b isa Symbol ? :($a = $str.$b)              :
            b isa Expr   ? :($a = $(_prepend!(b, str))) :
            error("ERROR!")
        return e
    end
end

"""
    @↓ a, c ← abs(b), ... = s

unpacks fields of structs and sub-structs.
"""
macro ↓(input)
    lhs, rhs = input.args[1:2]
    str = rhs isa Symbol ? rhs : rhs.args[2]
    objs = lhs isa Symbol || (lhs isa Expr && lhs.args[1] == :←) ? [lhs]    :
           lhs isa Expr && lhs.head == :tuple                    ? lhs.args :
           error("ERROR!")
    output = Expr(:block)
    for obj in objs
        push!(output.args, get_expr(str, obj))
    end
    esc(output)
end