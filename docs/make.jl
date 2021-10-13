using Documenter
using ArrowMacros

PAGES = [
    "Home" => "index.md",
    "Tests" => "tests.md"
]

makedocs(;
    sitename = "ArrowMacros.jl",
    format = Documenter.HTML(),
    modules = [ArrowMacros],
    pages = PAGES,
    authors = "Giancarlo A. Antonucci <giancarlo.antonucci@icloud.com>"
)

deploydocs(;
    repo = "https://github.com/giancarloantonucci/ArrowMacros.jl"
)
