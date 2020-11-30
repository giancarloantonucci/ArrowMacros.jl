function _prepend!(ex::Expr, s)
    for (i, ex_i) in enumerate(ex.args)
        if ex_i isa Symbol
            ex_i_string = string(ex_i)
            t = gensym()
            ex.args[i] = quote
                if ($ex_i) in fieldnames(typeof($s))
                    return $s.$ex_i
                else
                    return $ex_i
                end
            end
        elseif ex_i isa Expr
            ex.args[i] = _prepend!(ex_i, s)
        end
    end
    return ex
end

get_obj(s, obj::Symbol) = :($obj = $s.$obj)
function get_obj(s, obj::Expr)
    if obj.args[1] == :←
        a, b = obj.args[2:3]
        e = b isa Symbol ? :($a = $s.$b)              :
            b isa Expr   ? :($a = $(_prepend!(b, s))) :
            error("ERROR!")
        return e
    else
        error("ERROR!")
    end
end

"""
    @↓ a, c ← abs(b), ... = s

unpacks fields of structs and sub-structs.
"""
macro ↓(input)
    lhs, rhs = input.args[1:2]
    s = rhs isa Symbol ? rhs : rhs.args[2]
    objs = lhs isa Symbol || (lhs isa Expr && lhs.args[1] == :←) ? [lhs]    :
           lhs isa Expr && lhs.head == :tuple                    ? lhs.args :
           error("ERROR!")
    output = Expr(:block)
    for obj in objs
        ex = get_obj(s, obj)
        push!(output.args, ex)
    end
    esc(output)
end