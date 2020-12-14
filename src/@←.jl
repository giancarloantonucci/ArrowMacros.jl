"""
    @← a = f(b...)

changes `a = f(b...)` into one of the following (in this order):
1. `f!(a, b...)`
2. `f(a, b...)`
3. `a = f(b...)`
"""
macro ←(input)
    a = input.args[1]
    f = input.args[2].args[1]
    f! = Symbol(f, "!")
    b = input.args[2].args[2:end]
    output = quote
        b_ = ($(b...), )
        flag = try $a; true; catch; false; end
        flag && (@isdefined $f!) && hasmethod($f!, Tuple{typeof($a), typeof.(b_)...}) ? $f!($a, $(b...)) :
        flag && (@isdefined $f)  && hasmethod($f,  Tuple{typeof($a), typeof.(b_)...}) ? $f($a, $(b...))  :
        (@isdefined $f) && hasmethod($f,  Tuple{typeof.(b_)...})                      ? $a = $f($(b...)) :
        error("ERROR!")
    end
    esc(output)
end
