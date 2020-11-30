set_obj!(s, obj::Symbol) = :($s.$obj = $obj)
function set_obj!(s, obj::Expr)
    if obj.args[1] == :←
        b, a = obj.args[2:3]
        return :($s.$b = $a)
    else
        error("ERROR!")
    end
end

"""
    @↑ s = a, b ← abs(b), ...

packs fields into mutable structs or sub-structs.
"""
macro ↑(input)
    lhs, rhs = input.args[1:2]
    s = lhs isa Symbol ? lhs : lhs.args[2]
    objs = rhs isa Symbol || (rhs isa Expr && rhs.args[1] == :←) ? [rhs]    :
           rhs isa Expr && rhs.head == :tuple                    ? rhs.args :
           error("ERROR!")
    output = Expr(:block)
    for obj in objs
        ex = set_obj!(s, obj)
        push!(output.args, ex)
    end
    esc(output)
end