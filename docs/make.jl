using Documenter, windc_household_data



const _PAGES = [
    "Introduction" => ["index.md"],
]


makedocs(
    sitename="windc_household_data",
    authors="Mitch Phillipson",
    format = Documenter.HTML(),
    modules = [windc_household_data],
    pages = _PAGES
)



deploydocs(
    repo = "https://github.com/uw-windc/windc_household_data.jl",
    target = "build",
    branch = "gh-pages",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev" ],
    push_preview = true
)