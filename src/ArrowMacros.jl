module ArrowMacros

export @↓, @↑, @←

function _getfield_nested(s, b_string)
    b = Symbol(b_string)
    if isstructtype(typeof(s))
        if isdefined(s, b)
            return getfield(s, b)
        else
            for fieldname in fieldnames(typeof(s))
                field = getfield(s, fieldname)
                a = _getfield_nested(field, b_string)
                if a != nothing
                    return a
                end
            end
        end
    end
    return nothing
end

function _prepend!(b, s)
    for (i, b_i) in enumerate(b.args)
        if b_i isa Symbol
            b_i_string = String(b_i)
            t = gensym()
            b.args[i] = quote
                $t = $_getfield_nested($s, $b_i_string)
                if $t == nothing
                    $t = $b_i
                end
                $t
            end
        elseif b_i isa Expr
            b.args[i] = _prepend!(b_i, s)
        end
    end
    return b
end

# expression needs to be of form `s = a, b ← abs(b), ...`
macro ↓(input)
    s = input.args[1]
    t = input.args[2]
    vs = t isa Symbol ? [t] : t.args
    output = Expr(:block)
    for v in vs
        if v isa Symbol
            a = b = v
            b_string = String(b)
            push!(output.args, :($a = $_getfield_nested($s, $b_string)))
        elseif (v isa Expr) && (v.args[1] == :←)
            a, b = v.args[2:3]
            if b isa Symbol
                b_string = String(b)
                push!(output.args, :($a = $_getfield_nested($s, $b_string)))
            elseif b isa Expr
                _prepend!(b, s)
                push!(output.args, :($a = $b))
            end
        else
            error("dafuq?!")
        end
    end
    esc(output)
end

# expression needs to be of form `s = a, b ← abs(b), ...`
macro ↑(input)
    s = input.args[1]
    t = input.args[2]
    vs = t isa Symbol ? [t] : t.args
    output = Expr(:block)
    for v in vs
        if v isa Symbol
            a = b = v
            push!(output.args, :($s.$a = $b))
        elseif v isa Expr && v.args[1] == :←
            a, b = v.args[2:3]
            push!(output.args, :($s.$a = $b))
        else
            error("dafuq?!")
        end
    end
    esc(output)
end

# expression needs to be of form `a = f(b...)`
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
        error("dafuq?!")
    end
    esc(output)
end

end
