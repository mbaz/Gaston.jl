using Documenter, Gaston

makedocs(sitename = "Gaston.jl",
         pages = [
                  "Home" => "index.md",
                  "Introduction to plotting" => "introduction.md",
                  "2-D plotting tutorial" => "2dplots.md",
                  "3-D plotting tutorial" => "3dplots.md",
                  "Extending Gaston" => "extending.md",
                  "Managing multiple figures" => "figures.md",
                  "Gallery" => ["2-D Plots" => "2d-gallery.md",
                                "3-D Plots" => "3d-gallery.md"
                                ],
                  "Usage Notes and FAQ" => "faq.md",
                 ]
)
