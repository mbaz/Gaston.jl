using Documenter, Gaston

# Build docs.
makedocs(sitename = "Gaston.jl",
         build = "build/v2",
         pages = [
                  "Introduction" => "index.md",
                  "Examples" => "examples.md",
                  "Manual" => "plotguide.md",
                  "Reference" => "api.md",
                  ],
         pagesonly = true,
         format = Documenter.HTML(prettyurls = false), # set to true when deploying
         authors = "Miguel Bazdresch and contributors",
)

# Make sure all gnuplot processes are closed.
closeall()
