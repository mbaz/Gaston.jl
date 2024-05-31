### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ a4695d0e-59f5-458a-8b95-ea91d8f5d147
import Pkg

# ╔═╡ 65a89424-5f43-406e-bdd2-85338915b7f2
# ╠═╡ show_logs = false
Pkg.add("PlutoUI")

# ╔═╡ 92d4608a-1a99-41a9-beef-c002d8c146fb
# ╠═╡ show_logs = false
Pkg.develop(path="/home/miguel/rcs/jdev/Gaston")

# ╔═╡ 9e2ec510-8855-4b69-bb05-89ff7a42e646
# ╠═╡ show_logs = false
begin
	Pkg.add("QuadGK")
	using QuadGK
end

# ╔═╡ aa4a033e-2d5e-4718-a5a4-b892367e614e
using Revise

# ╔═╡ ca39255c-714e-4065-b5a9-1b4810bf699b
using Gaston

# ╔═╡ a5bedf71-aed3-4ae8-b9a8-3ebbd41039e5
using PlutoUI

# ╔═╡ c57f944e-5890-43c6-8f69-1dcde63994c2
Gaston.GASTON_VERSION

# ╔═╡ f926be1c-d34d-4df1-a6fc-0a1b70cc35de
PlutoUI.TableOfContents(title = "Contents")

# ╔═╡ bbe19693-ed57-4702-9902-6dc2f1ef88ce
Gaston.config.term = "pngcairo font ',10' size 700,700"

# ╔═╡ 9d7ac638-a10a-440b-add4-dcb04bbd3d9d
md"### Contour lines on heatmap"

# ╔═╡ def3fd60-0633-11ee-0a41-f95c664220bd
md"https://gnuplot-tricks.blogspot.com/2009/07/maps-contour-plots-with-labels.html"

# ╔═╡ becbb113-0bef-48b4-adb8-ec381e5622cd
let
	# define function to plot
	f(x,y)=sin(1.3*x)*cos(0.9*y)+cos(.8*x)*sin(1.9*y)+cos(y*.2*x)
	# obtain function contours
	settings = """set contour base
	              set cntrparam level incremental -3, 0.5, 3
				  unset surface"""
	x = y = range(-5, 5, 100)	            
	contours = Gaston.plotwithtable(settings, x, y, f)
	# calculate meshgrid for heatmap plot
	z = Gaston.meshgrid(x, y, f)
	# plot heatmap followed by contours
	plot("""unset key
		    unset colorbox
	        set palette rgbformulae 33,13,10""",
		 x, y, z, "with image")
	plot!(contours, "w l lw 0.5 lc 'dark-goldenrod'")
end

# ╔═╡ 518deb0b-350e-41a1-ae63-3ddfdc59f254
md"### Euler spiral"

# ╔═╡ a3e92f69-73d9-45d2-9a1a-565808c71832
let
	z = range(-5, 5, 200)
	fx(z) = sin(z^2)
	fy(z) = cos(z^2)
	x = [quadgk(fx, 0, t)[1] for t in z]
	y = [quadgk(fy, 0, t)[1] for t in z]
	splot("""unset zeroaxis
	         set tics border
	         set xyplane at -5 
	         set view 65,35
	         set border 4095""",
		  x, y, z, "w l lc 'black' lw 1.5")
end

# ╔═╡ 4b4c8d4e-caab-4ef2-931a-1005bbc8317f
md"### Waterfall"

# ╔═╡ 318fe2a5-efe9-4cfd-b2ca-0623d18ded61
let
	x = -15:0.1:15
	y = 0:30
    u1data = [exp(-(x-0.5*(y-15))^2) for x in x, y in y]
	Zf = fill(0.0, length(x))
	f = Figure()
	Gaston.set!(f(1), """set zrange [0:2]
	               set tics out
	               set ytics border
	               set xyplane at 0
				   set view 45,5
				   set zrange [0:3]
	               set xlabel 'ξ' offset -0,-2
	               set ylabel 't'
	               set zlabel '|u|'
	               set border 21""")
	for i in reverse(eachindex(y))
		Y = fill(y[i], length(x))
		Z = u1data[:,i]
		splot!(x, Y, Z, Zf, Z, "w zerrorfill lc 'black' fillstyle solid 1.0 fc 'white'")
	end
	f
end

# ╔═╡ f0030a90-93c0-4e55-8f1f-9b54449c7c45
closeall()

# ╔═╡ Cell order:
# ╠═a4695d0e-59f5-458a-8b95-ea91d8f5d147
# ╠═65a89424-5f43-406e-bdd2-85338915b7f2
# ╠═92d4608a-1a99-41a9-beef-c002d8c146fb
# ╠═aa4a033e-2d5e-4718-a5a4-b892367e614e
# ╠═ca39255c-714e-4065-b5a9-1b4810bf699b
# ╠═c57f944e-5890-43c6-8f69-1dcde63994c2
# ╠═a5bedf71-aed3-4ae8-b9a8-3ebbd41039e5
# ╠═f926be1c-d34d-4df1-a6fc-0a1b70cc35de
# ╠═bbe19693-ed57-4702-9902-6dc2f1ef88ce
# ╠═9d7ac638-a10a-440b-add4-dcb04bbd3d9d
# ╠═def3fd60-0633-11ee-0a41-f95c664220bd
# ╠═becbb113-0bef-48b4-adb8-ec381e5622cd
# ╠═518deb0b-350e-41a1-ae63-3ddfdc59f254
# ╠═9e2ec510-8855-4b69-bb05-89ff7a42e646
# ╠═a3e92f69-73d9-45d2-9a1a-565808c71832
# ╠═4b4c8d4e-caab-4ef2-931a-1005bbc8317f
# ╠═318fe2a5-efe9-4cfd-b2ca-0623d18ded61
# ╠═f0030a90-93c0-4e55-8f1f-9b54449c7c45
