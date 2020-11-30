function _deep_getfield(s, b)
    if isstructtype(typeof(s))
        if isdefined(s, b)
            return getfield(s, b)
        else
            for fn in fieldnames(typeof(s))
                field = getfield(s, fn)
                a = _deep_getfield(field, b)
                if a != b
                    return a
                end
            end
        end
    end
    return b
end

function _deep_prepend!(ex, s)
    for (i, ex_i) in enumerate(ex.args)
        if ex_i isa Symbol
            ex_i_string = string(ex_i)
            t = gensym()
            ex.args[i] = quote
                $t = $_deep_getfield($s, Symbol($ex_i_string))
                if $t isa Symbol
                    $t = $ex_i
                end
                $t
            end
        elseif ex_i isa Expr
            ex.args[i] = _deep_prepend!(ex_i, s)
        end
    end
    return ex
end

"""
    @⤓ a, b ← abs(b), ... = s

unpacks fields of structs and sub-structs.
"""
macro ⤓(input)
    s = input.args[2]
    vars = input.args[1]
    vars = vars isa Symbol ? [vars] : vars.args
    output = Expr(:block)
    for v in vars
        if v isa Symbol
            a = b = v
        elseif (v isa Expr) && (v.args[1] == :←)
            a, b = v.args[2:3]
        end
        b_ = string(b)
        if b isa Symbol
            push!(output.args, :($a = $_deep_getfield($s, Symbol($b_))))
        elseif b isa Expr
            ex = b
            _deep_prepend!(ex, s)
            push!(output.args, :($a = $ex))
        end
    end
    esc(output)
end