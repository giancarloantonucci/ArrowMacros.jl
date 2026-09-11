"""
ArrowMacros provides `@↓` ("download": unpack struct fields into locals) and
`@↑` ("upload": write locals back into struct fields) — the syntactic spine
of the NSDE packages. Field access goes through `Val`-specialized
`getproperty`/`setproperty!`, so the sugar costs nothing at run time.
"""
module ArrowMacros

export @↓, @↑

include("@↓.jl")
include("@↑.jl")

end
