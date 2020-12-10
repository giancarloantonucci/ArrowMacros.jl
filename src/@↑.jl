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
    LHS, RHS = input.args[1:2]
    s = LHS
    objs = RHS isa Symbol || (RHS isa Expr && RHS.args[1] == :←) ? [RHS]    :
           RHS isa Expr && RHS.head == :tuple                    ? RHS.args :
           error("ERROR!")
    output = Expr(:block)
    for obj in objs
        ex = set_obj!(s, obj)
        push!(output.args, ex)
    end
    esc(output)
end