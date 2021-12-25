using LuckyImaging
using Documenter

DocMeta.setdocmeta!(LuckyImaging, :DocTestSetup, :(using LuckyImaging); recursive=true)

makedocs(;
    modules=[LuckyImaging],
    authors="Miles Lucas <mdlucas@hawaii.edu> and contributors",
    repo="https://github.com/JuliaHCI/LuckyImaging.jl/blob/{commit}{path}#{line}",
    sitename="LuckyImaging.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API/Reference" => "api.md"
    ],
)

deploydecs(;
    devbranch="main",
    repo="github.com/JuliaHCI/LuckyImaging.jl",
)