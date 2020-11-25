module ArrowMacros

export @↓, @↑, @⤓, @⤒, @←

function _getfield(constr, name)
    if isstructtype(typeof(constr))
        if isdefined(constr, name)
            return getfield(constr, name)
        end
    end
    return name
end

function _prepend!(ex, constr)
    for (i, ex_i) in enumerate(ex.args)
        if ex_i isa Symbol
            ex_i_string = String(ex_i)
            t = gensym()
            ex.args[i] = quote
                $t = $_getfield($constr, Symbol($ex_i_string))
                if $t isa Symbol
                    $t = $ex_i
                end
                $t
            end
        elseif ex_i isa Expr
            ex.args[i] = _prepend!(ex_i, constr)
        end
    end
    return ex
end

"""
    @↓ a, b ← abs(b), ... = s

unpacks fields of structs and sub-structs.
"""
macro ↓(input)
    constr = input.args[2]
    blocks = input.args[1]
    blocks = blocks isa Symbol ? [blocks] : blocks.args
    output = Expr(:block)
    for block in blocks
        if block isa Symbol
            value = name = block
        elseif (block isa Expr) && (block.args[1] == :←)
            value, name = block.args[2:3]
        end
        name_ = string(name)
        if name isa Symbol
            push!(output.args, :($value = $_getfield($constr, Symbol($name_))))
        elseif name isa Expr
            ex = name
            _prepend!(ex, constr)
            push!(output.args, :($value = $ex))
        end
    end
    esc(output)
end

function _deep_getfield(constr, name)
    if isstructtype(typeof(constr))
        if isdefined(constr, name)
            return getfield(constr, name)
        else
            for fn in fieldnames(typeof(constr))
                field = getfield(constr, fn)
                value = _deep_getfield(field, name)
                if value != name
                    return value
                end
            end
        end
    end
    return name
end

function _deep_prepend!(ex, constr)
    for (i, ex_i) in enumerate(ex.args)
        if ex_i isa Symbol
            ex_i_string = String(ex_i)
            t = gensym()
            ex.args[i] = quote
                $t = $_deep_getfield($constr, Symbol($ex_i_string))
                if $t isa Symbol
                    $t = $ex_i
                end
                $t
            end
        elseif ex_i isa Expr
            ex.args[i] = _deep_prepend!(ex_i, constr)
        end
    end
    return ex
end

"""
    @⤓ a, b ← abs(b), ... = s

unpacks fields of structs and sub-structs.
"""
macro ⤓(input)
    constr = input.args[2]
    blocks = input.args[1]
    blocks = blocks isa Symbol ? [blocks] : blocks.args
    output = Expr(:block)
    for block in blocks
        if block isa Symbol
            value = name = block
        elseif (block isa Expr) && (block.args[1] == :←)
            value, name = block.args[2:3]
        end
        name_ = string(name)
        if name isa Symbol
            push!(output.args, :($value = $_deep_getfield($constr, Symbol($name_))))
        elseif name isa Expr
            ex = name
            _deep_prepend!(ex, constr)
            push!(output.args, :($value = $ex))
        end
    end
    esc(output)
end

function _setfield!(constr, name, value)
    if isstructtype(typeof(constr))
        if isdefined(constr, name)
            return setfield!(constr, name, value)
        end
    end
    return name
end

"""
    @↑ s = a, b ← abs(b), ...

packs fields into mutable structs or sub-structs.
"""
macro ↑(input)
    constr = input.args[1]
    blocks = input.args[2]
    blocks = blocks isa Symbol ? [blocks] : blocks.args
    output = Expr(:block)
    for block in blocks
        if block isa Symbol
            name = value = block
        elseif block isa Expr && block.args[1] == :←
            name, value = block.args[2:3]
        end
        name_ = string(name)
        push!(output.args, :($_setfield!($constr, Symbol($name_), $value)))
    end
    esc(output)
end

function _deep_setfield!(constr, name, value)
    if isstructtype(typeof(constr))
        if isdefined(constr, name)
            return setfield!(constr, name, value)
        else
            for fn in fieldnames(typeof(constr))
                field = getfield(constr, fn)
                _deep_setfield!(field, name, value)
            end
        end
    end
    return name
end

"""
    @⤒ s = a, b ← abs(b), ...

packs fields into mutable structs or sub-structs.
"""
macro ⤒(input)
    constr = input.args[1]
    blocks = input.args[2]
    blocks = blocks isa Symbol ? [blocks] : blocks.args
    output = Expr(:block)
    for block in blocks
        if block isa Symbol
            name = value = block
        elseif block isa Expr && block.args[1] == :←
            name, value = block.args[2:3]
        end
        name_ = string(name)
        push!(output.args, :($_deep_setfield!($constr, Symbol($name_), $value)))
    end
    esc(output)
end

"""
    @← a = f(b...)

changes into one of the following, in order of precedence:
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
        b_ = ($(b...),)
        (@isdefined $f!) && hasmethod($f!, Tuple{typeof($a), typeof.(b_)...}) ? $f!($a, $(b...)) :
        (@isdefined $f)  && hasmethod($f,  Tuple{typeof($a), typeof.(b_)...}) ? $f($a, $(b...))  :
        (@isdefined $f)  && hasmethod($f,  Tuple{typeof.(b_)...})             ? $a = $f($(b...)) :
        error("ERROR!")
    end
    esc(output)
end

end
