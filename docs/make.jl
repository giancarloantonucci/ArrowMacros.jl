using Documenter
using ArrowMacros

cp(joinpath(@__DIR__, "..", "README.md"), joinpath(@__DIR__, "src", "index.md"); force=true)

makedocs(;
    sitename="ArrowMacros.jl",
    format=Documenter.HTML(),
    modules=[ArrowMacros],
    pages=["Home" => "index.md", "API" => "api.md"],
    checkdocs=:exports,  # every export must carry a docstring, or the build fails
    authors="Giancarlo A. Antonucci <giancarlo.antonucci@icloud.com>",
)

deploydocs(; repo="github.com/giancarloantonucci/ArrowMacros.jl.git")
