"""
    @← a = f(b...)

returns either `a = f(b...)` or `f!(a, b...)`, in this order.
"""
macro ←(input)
    a = input.args[1]
    f = input.args[2].args[1]
    f! = Symbol(f, "!")
    b = input.args[2].args[2:end]
    output = quote
        if (@isdefined $f)
            $a = $f($(b...))
        elseif (@isdefined $f!) && (@isdefined $a)
            $f!($a, $(b...))
        end
    end
    esc(output)
end
