module ArrowMacros

export @↓, @↑, @⤓, @⤒, @←

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

function _setfield!(s, b, a)
    if isstructtype(typeof(s))
        if isdefined(s, b)
            return setfield!(s, b, a)
        end
    end
    return b
end

"""
    @↑ s = a, b ← abs(b), ...

packs fields into mutable structs or sub-structs.
"""
macro ↑(input)
    s = input.args[1]
    vars = input.args[2]
    vars = vars isa Symbol ? [vars] : vars.args
    output = Expr(:block)
    for v in vars
        if v isa Symbol
            b = a = v
        elseif v isa Expr && v.args[1] == :←
            b, a = v.args[2:3]
        end
        b_ = string(b)
        push!(output.args, :($_setfield!($s, Symbol($b_), $a)))
    end
    esc(output)
end

function _deep_setfield!(s, b, a)
    if isstructtype(typeof(s))
        if isdefined(s, b)
            return setfield!(s, b, a)
        else
            for fn in fieldnames(typeof(s))
                field = getfield(s, fn)
                _deep_setfield!(field, b, a)
            end
        end
    end
    return b
end

"""
    @⤒ s = a, b ← abs(b), ...

packs fields into mutable structs or sub-structs.
"""
macro ⤒(input)
    s = input.args[1]
    vars = input.args[2]
    vars = vars isa Symbol ? [vars] : vars.args
    output = Expr(:block)
    for v in vars
        if v isa Symbol
            b = a = v
        elseif v isa Expr && v.args[1] == :←
            b, a = v.args[2:3]
        end
        b_ = string(b)
        push!(output.args, :($_deep_setfield!($s, Symbol($b_), $a)))
    end
    esc(output)
end

"""
    @← a = f(b...)

changes `a = f(b...)` into one of the following (in this order):
1. `f!(a, b...)`,
2. `f(a, b...)`,
3. `a = f(b...)`.
"""
macro ←(input)
    a = input.args[1]
    f = input.args[2].args[1]
    f! = Symbol(f, "!")
    b = input.args[2].args[2:end]
    output = quote
        b_ = ($(b...), )
        ⚐ = try $a; true; catch; false; end
        !⚐ && (@isdefined $f)  && hasmethod($f,  Tuple{typeof.(b_)...})             ? $a = $f($(b...)) :
        ⚐  && (@isdefined $f!) && hasmethod($f!, Tuple{typeof($a), typeof.(b_)...}) ? $f!($a, $(b...)) :
        ⚐  && (@isdefined $f)  && hasmethod($f,  Tuple{typeof($a), typeof.(b_)...}) ? $f($a, $(b...))  :
        error("ERROR!")
    end
    esc(output)
end

end