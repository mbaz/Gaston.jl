### A Pluto.jl notebook ###
# v0.20.10

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 93b3b71e-0a4e-4165-9f92-b770c06a5964
# ╠═╡ show_logs = false
begin
	import Pkg
	Pkg.add("PlutoUI")
	Pkg.develop(path="/home/miguel/rcs/jdev/Gaston")
	using Revise
	using Gaston
	using PlutoUI
	Gaston.GASTON_VERSION
end

# ╔═╡ a86a096a-f66b-11ed-3c0d-f3dce992f2d7
md"# Gaston demo/tutorial: 3-D Plots

Let's start by loading needed packages: Gaston."

# ╔═╡ 198a01e0-fa6c-426f-b485-ae2922da121f
PlutoUI.TableOfContents(title = "Contents")

# ╔═╡ af9f5b7f-84ec-4f53-a4ba-df4dd73933b6
Gaston.config.term = "pngcairo font ',10' size 700,400"

# ╔═╡ 1851bc4f-c625-4c14-96b3-c8fce30b2182
md"## 3-D plots

To create a 3-D plot, use the `splot` function or the `@splot` macro. The following examples illustrate their use."

# ╔═╡ 9a92ee79-8db5-4532-ad7b-046700d1cd84
md"##### z values as an array"

# ╔═╡ 5e3d28f4-9500-44ec-82fb-dc6ee8f8d239
let
    z = [10 10 10 10 ;
		 10  5  1  0 ;
		 10 10 10 10 ]
	splot("set title 'A Valley'
		   set hidden3d
	       set view 75, 38",
		  z,
		  "lc 'dark-green'") 
end

# ╔═╡ 97dc9773-310d-44bf-b518-baead81cd252
md"##### x, y vectors or ranges; z an array"

# ╔═╡ 4586bc09-8556-4627-b473-8f168f62bfb5
let
	x = -2:1
    y = [2, 3, 4]
    z = [10 10 10 10 ;
		 10  5  1  0 ;
		 10 10 10 10 ]
	splot("set title 'A Valley'
		   set hidden3d
	       set view 75, 38
	       set xlabel 'x' offset -1.5,-1.5 
	       set ylabel 'y' offset 1,1
	       set zlabel 'z'",
		  x, y, z,
		  "lc 'dark-green'") 
end

# ╔═╡ 6d34cafc-164e-4731-b0fc-0f586bf7e994
md"##### x and y vectors or ranges; z a function"

# ╔═╡ e7697a24-f587-4215-9cfa-5416e0b2627f
let
	x = y = -15:0.4:15
	f1(x,y) = @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
	splot("set title 'Sombrero'
		   set hidden3d",
		  x, y, f1,
		  "lc 'turquoise'") 
end

# ╔═╡ 3dc0145f-49df-4c29-a5e1-12d158f901bc
md"If `x` and `y` are not provided, then `range(-10, 10, 100)` is used by default."

# ╔═╡ b09cfaf6-b56b-4818-bda8-83a9a98e7b6d
md"##### x and/or y tuples; z a function"

# ╔═╡ a73fbdfa-452a-4fbc-821a-1e00046c602d
let
	splot("set hidden3d",
		  (-6, 6, 20), (-3, 3, 20), (x,y) -> cos.(x./2).*sin.(y./2))
end

# ╔═╡ 470f890e-9010-4ee4-abc3-f5c5c73c233b
md"The format is either `(min, max)` or `(min, max, samples)`. The default number of samples is 100. If only one tuple is provided, it's assumed to specify values for both `x` and `y`. The default is `(-10, 10, 100)`."

# ╔═╡ 1ceb96e8-fecb-4f1e-9457-3717532766d9
md"## Plot styles

The following plot styles are provided:

* `surf` and `surf!` to plot surfaces.
* `contour` for contour plots.
* `surfcontour` combines the previous two styles.
* `scatter3` and `scatter3!` for scatter plots.
* `wireframe` and `wireframe!` for wireframe plots.
* `wiresurf` and `wiresurf!` combine a surface and a wireframe.
* `heatmap` is a projection of a surface or 3-D histogram to a plane.

The following examples illustrate these styles."

# ╔═╡ b67cf328-1659-46f4-afcd-d393836035bc
md"##### Surface plots"

# ╔═╡ ebe88c25-eded-4643-aac5-175013a8bd3d
let
	f1(x,y) = sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
	@gpkw surf({title = "'Sombrero Surface'",
	            hidden3d,
	            palette = :matter},
		        (-15, 15, 200), f1)
end

# ╔═╡ 24893b90-a180-4df2-a5cb-c252920f74d6
md"##### Contour plots"

# ╔═╡ de4c0f15-e0b9-406f-b777-a8eea53491dc
let
	f1(x,y) = cos(x/2)*sin(y/2)
	contour("set title  'Sombrero Contours'", (-10, 10, 50), f1)
end

# ╔═╡ 3ba30e9c-3ce5-4e02-8225-b611f9631675
md"Labels can be removed with the `labels = false` argument:"

# ╔═╡ 426d3c69-d7c2-4bfa-a63d-79da7d0f4c8f
let
	f1(x,y) = cos(x/2)*sin(y/2)
	contour("set title  'Sombrero Contours; no labels'",
		    (-10, 10, 50), f1, labels = false)
end

# ╔═╡ 57e27251-9723-429c-976e-61208dcd61f0
let
	f1(x,y) = @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
	surfcontour("set title 'Sombrero Wireframe and Contours'",
		        (-15, 15, 40), f1, "lc 'orange'")
end

# ╔═╡ 59efd1da-b92d-4edf-b8e1-4ac375cf9485
md"##### Scatter plots"

# ╔═╡ 015d489d-a51d-47ae-8899-4ee04a064ec0
md"Scatter plots use the `points` pointstyle."

# ╔═╡ dbeeaaa0-d0da-455d-b3c5-e1a3405014e0
let
	scatter3("set title 'A 3-D scatter plot",
		     randn(10), randn(10), randn(10))
end

# ╔═╡ 070eb594-80f9-48ed-a416-ef7eeb53a97e
let
	x = 0:0.1:6π
	@splot({title = "'Trigonometric spiral'",
	        colorbox = false,
	        palette = :matter},
		   x, x.*cos.(x), x.*sin.(x), x./10,
	       "with p pt 7 lc palette ps variable")
end

# ╔═╡ 09901ab7-298f-456b-aa92-db1d642c36ce
md"##### Wireframe plots"

# ╔═╡ ebd8dc6f-3d5b-4ce6-992e-41be7a19767d
md"Wireframe plots use the `lines` plotstyle, which is `gnuplot`'s default and is illustraded above. The following example shows how to plot a surface and a wireframe:"

# ╔═╡ c76118f4-9e8f-4c8c-8cce-df23126551c9
let
	f1(x, y) = cos(x/2) * sin(y/2)
	theme = @gpkw {palette = :matter, title = Q"Wiresurf plot"}
	wiresurf(theme, :notics, :labels, (-10, 10, 30), f1)
end

# ╔═╡ d10136b4-b397-4388-9bc6-b3194341a918
md"##### Heatmap plots"

# ╔═╡ 729f87a6-e861-425a-a405-cad1ec4fb320
let
	f1(x, y) = cos(x/2) * sin(y/2)
	theme = @gpkw {palette = :matter, title = Q"Heatmap"}
	heatmap(theme, :notics, :labels, (-10, 10, 70), f1)
end

# ╔═╡ 5f3c4090-417f-4616-b268-735be74fc3ae
md"## Interactivity"

# ╔═╡ 7bc6cd91-ce7c-4800-a36a-ec12dedf5a9d
md"Interaction with notebook sliders and other widgets works in a similar way to regular 2-D plots."

# ╔═╡ dca8473a-dac9-438b-9d86-987bdc1631ba
md"Azimuth: $(@bind az Slider(0:180, default = 115, show_value = true))"

# ╔═╡ 094b2a61-30b8-4739-a125-cb1e1a37dff7
md"Altitude: $(@bind al Slider(0:90, default = 55, show_value = true))"

# ╔═╡ 77843582-1942-471d-987b-4b4a03adfecf
md"""Palette: $(@bind p Select([:viridis => "viridis", :matter => "matter", :ice => "ice", :thermal => "thermal"]))"""

# ╔═╡ 5a5a8dae-526d-4122-856a-f712cfaaf858
let al = al, az = az
	f1(x, y) = cos(x/2) * sin(y/2)
	theme = @gpkw {view = (al, az),
	               palette = p,
				   title = Q"Wiresurf plot"}
	wiresurf(theme, :notics, :labels, (-8, 8, 30), f1)
end

# ╔═╡ 28b107c9-4f20-415e-b68e-d204798c94c8
md"## Animation

Animation works in a similar way to 1-D plots."

# ╔═╡ 40b076e3-92ba-48fe-90bf-f94078370b20
let
	f = Figure()
	function z(x, y, i)
		if 1.8 < atan(y, x)+π < 2.7
			return NaN
		end
		d = sqrt(x*x+y*y)
		i*sin(2d) / d
	end
	x = y = range(-10, 10, 35)
	theme = @gpkw {zrange = (-1.5, 1.5),
	               cbrange = (-0.5, 1),
				   colorbox = false,
	               palette = :matter}
	frames = 20
	for (idx, i) in enumerate(range(-1, 1, frames))
		wiresurf(f[idx], theme, :notics, x, y, (x, y) -> z(x, y, i))
	end
	for (idx, i) in enumerate(range(1, -1, frames))
		wiresurf(f[idx+frames], theme, :notics, x, y, (x, y) -> z(x, y, i))
	end
	animate(f, "gif animate loop 0 size 700,400")
end

# ╔═╡ Cell order:
# ╟─a86a096a-f66b-11ed-3c0d-f3dce992f2d7
# ╠═93b3b71e-0a4e-4165-9f92-b770c06a5964
# ╠═198a01e0-fa6c-426f-b485-ae2922da121f
# ╠═af9f5b7f-84ec-4f53-a4ba-df4dd73933b6
# ╟─1851bc4f-c625-4c14-96b3-c8fce30b2182
# ╟─9a92ee79-8db5-4532-ad7b-046700d1cd84
# ╠═5e3d28f4-9500-44ec-82fb-dc6ee8f8d239
# ╟─97dc9773-310d-44bf-b518-baead81cd252
# ╠═4586bc09-8556-4627-b473-8f168f62bfb5
# ╟─6d34cafc-164e-4731-b0fc-0f586bf7e994
# ╠═e7697a24-f587-4215-9cfa-5416e0b2627f
# ╟─3dc0145f-49df-4c29-a5e1-12d158f901bc
# ╟─b09cfaf6-b56b-4818-bda8-83a9a98e7b6d
# ╠═a73fbdfa-452a-4fbc-821a-1e00046c602d
# ╟─470f890e-9010-4ee4-abc3-f5c5c73c233b
# ╟─1ceb96e8-fecb-4f1e-9457-3717532766d9
# ╟─b67cf328-1659-46f4-afcd-d393836035bc
# ╠═ebe88c25-eded-4643-aac5-175013a8bd3d
# ╟─24893b90-a180-4df2-a5cb-c252920f74d6
# ╠═de4c0f15-e0b9-406f-b777-a8eea53491dc
# ╟─3ba30e9c-3ce5-4e02-8225-b611f9631675
# ╠═426d3c69-d7c2-4bfa-a63d-79da7d0f4c8f
# ╠═57e27251-9723-429c-976e-61208dcd61f0
# ╟─59efd1da-b92d-4edf-b8e1-4ac375cf9485
# ╟─015d489d-a51d-47ae-8899-4ee04a064ec0
# ╠═dbeeaaa0-d0da-455d-b3c5-e1a3405014e0
# ╠═070eb594-80f9-48ed-a416-ef7eeb53a97e
# ╟─09901ab7-298f-456b-aa92-db1d642c36ce
# ╟─ebd8dc6f-3d5b-4ce6-992e-41be7a19767d
# ╠═c76118f4-9e8f-4c8c-8cce-df23126551c9
# ╟─d10136b4-b397-4388-9bc6-b3194341a918
# ╠═729f87a6-e861-425a-a405-cad1ec4fb320
# ╟─5f3c4090-417f-4616-b268-735be74fc3ae
# ╟─7bc6cd91-ce7c-4800-a36a-ec12dedf5a9d
# ╟─dca8473a-dac9-438b-9d86-987bdc1631ba
# ╟─094b2a61-30b8-4739-a125-cb1e1a37dff7
# ╟─77843582-1942-471d-987b-4b4a03adfecf
# ╠═5a5a8dae-526d-4122-856a-f712cfaaf858
# ╟─28b107c9-4f20-415e-b68e-d204798c94c8
# ╠═40b076e3-92ba-48fe-90bf-f94078370b20
