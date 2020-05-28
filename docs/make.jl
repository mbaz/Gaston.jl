using Documenter, Gaston

makedocs(sitename="Gaston.jl",
         pages = [
                  "Home" => "index.md",
                  "Introduction" => "introduction.md",
                  "Examples" => ["2-D Plots" => "2d-examples.md",
                                 "3-D Plots" => "3dplots.md"
                                ],
                  "Settings and Configuration" => "settings.md",
                  "Usage Notes and FAQ" => "notes.md"
                 ]
)
