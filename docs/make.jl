using Documenter
using ArrowMacros

PAGES = [
    "Home" => "index.md",
    "API" => "api.md"
]

makedocs(;
    sitename = "ArrowMacros.jl",
    format = Documenter.HTML(),
    modules = [ArrowMacros],
    pages = PAGES,
    checkdocs = :exports, # every export must carry a docstring, or the build fails
    authors = "Giancarlo A. Antonucci <giancarlo.antonucci@icloud.com>"
)

deploydocs(;
    repo = "github.com/giancarloantonucci/ArrowMacros.jl.git"
)
