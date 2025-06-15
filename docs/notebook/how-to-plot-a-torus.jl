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

# ╔═╡ 4bd21a1f-900c-4837-b121-6e708ed9e178
import Pkg

# ╔═╡ 4a857a54-37f5-45d5-a715-95614ee569fe
# ╠═╡ show_logs = false
Pkg.add("PlutoUI")

# ╔═╡ fd4dbf2c-3e9d-4a9e-8d45-0976c6fbd46c
# ╠═╡ show_logs = false
Pkg.develop(path="/home/miguel/rcs/jdev/Gaston")

# ╔═╡ 2fd048bc-2e87-490a-afc2-5c216d260e77
using Gaston

# ╔═╡ 4ccbcb36-2fb7-495a-ac80-3d4eab0f4471
using PlutoUI

# ╔═╡ 05614214-fb38-4170-acfe-66b90b88c283
md"# Gaston demo/tutorial

## How to plot one (or two) torus

This demo/tutorial shows how to use Gaston in a Pluto notebook, including interactive plots. Some auxiliary functions used throughout the tutorial are defined at the end of the notebook. 

Let's start by loading Gaston and PlutoUI."

# ╔═╡ 8fa8505a-98c8-46bf-a716-dba45626b98a
PlutoUI.TableOfContents(title = "Contents")

# ╔═╡ a87cb7e3-18e4-49d3-a8db-31b7bbeacae0
import LinearAlgebra: norm, cross, dot

# ╔═╡ 65a53ffa-c8c0-448b-957a-ea9c55928057
md"""### Step 1: plotting a circle in three dimensions

Our first task is to draw circles of arbitrary size at arbitrary postions in space.

Consider a circle of radius $r$ centered at $p \in \mathbb{R}^3$ on the plane defined by the orthonormal vectors $\mathbf{v}_1$ and $\mathbf{v}_2$. The parametric equation of this circle is

$[x, y, z] = p + r\cos(t)\mathbf{v}_1 + r\sin(t)\mathbf{v}_2.$

Let's test this out:
"""

# ╔═╡ 053a7600-c582-4498-a848-e704fc1dd927
md"""#### Parameters
center x: $(@bind cx Slider(-5:0.1:5, default = 0, show_value = true))

center y: $(@bind cy Slider(-5:0.1:5, default = 0, show_value = true))

center z: $(@bind cz Slider(-5:0.1:5, default = 0, show_value = true))

radius: $(@bind r Slider(0.1:0.1:3, default = 1, show_value = true))

orientation θ: $(@bind θ Slider(0:0.05:π, default = 0, show_value = true))

orientation ρ: $(@bind ρ Slider(0:0.05:2π, default = 0, show_value = true))
"""

# ╔═╡ 3480c76e-a643-4856-a51a-a4b621c7b545
md"""### Step 2: Plotting a donut frame

Now that we know how to plot arbitrary circles, we'll draw a bunch of small circles making a ring around a larger one. These will form the frame of "skeleton" of the torus. 

Let's draw the frame of a torus of major radius $r_M$ and minor radius $r_m$."""

# ╔═╡ e7906ae5-e460-4d28-af8b-948415310d3d
md"#### Radii

rM $(@bind rM Slider(0.1:0.1:2, default = 1, show_value = true))
rm $(@bind rm Slider(0.1:0.1:1, default = 0.1, show_value = true))"

# ╔═╡ 036ae8fa-e6ba-4d06-94f9-c64c7b87507f
md"""### Step 3: Plotting the torus' surface

In order to "fill" the torus' frame, we need to stack the coordinates of all the small circles and pass them to `splot`. Gnuplot will automatically create a wireframe connecting the vertices of neighboring circles. Using the `pm3d` plotstyle, gnuplot will apply surface and lighting effects to the torus frame. To see the wireframe, plot using `with lines`.

"""

# ╔═╡ 1de39361-2264-4bdd-8694-462d41436a81
md"""#### Center
cx: $(@bind c2x Slider(-5:0.1:5, default = 0, show_value = true))

cy: $(@bind c2y Slider(-5:0.1:5, default = 0, show_value = true))

cz: $(@bind c2z Slider(-5:0.1:5, default = 0, show_value = true))
"""

# ╔═╡ 4a0cdeda-1d93-4be9-8e79-e1510a9fe1e7
md"""### Step 4: Rotate the torus

Now, we will apply a rotation to the torus using angles along the x, y and z axes."""

# ╔═╡ 07294d8b-b01c-4528-8217-0572466f9eaa
md"""#### Center
cx: $(@bind c3x Slider(-5:0.1:5, default = 0, show_value = true))

cy: $(@bind c3y Slider(-5:0.1:5, default = 0, show_value = true))

cz: $(@bind c3z Slider(-5:0.1:5, default = 0, show_value = true))

#### Angle

θx: $(@bind θx Slider(0:0.05:3.15, default = 0, show_value = true))

θy: $(@bind θy Slider(0:0.05:3.15, default = 0, show_value = true))

θz: $(@bind θz Slider(0:0.05:6.3, default = 0, show_value = true))
"""

# ╔═╡ 7e89c619-c951-45eb-adfc-8e91f42d7e60
md"""### Conclusion

Now that we know how to plot arbitrary torii, let's draw two of them with high resolution."""

# ╔═╡ e47bb743-75ba-427d-9301-a15cea857be3
md"Support code"

# ╔═╡ 22941298-cc85-45d1-9fc7-96b2a1e6d863
begin
	ft = Figure("torus")
	fti = Figure("torii")
	nothing
end

# ╔═╡ 9d71d2ee-c194-49cf-ab41-c99500d36298
"Circle parametric equation"
function paramcircle(p, r, v1, v2, t)
	x = p[1] + r*cos(t)*v1[1] + r*sin(t)*v2[1]
	y = p[2] + r*cos(t)*v1[2] + r*sin(t)*v2[2]
	z = p[3] + r*cos(t)*v1[3] + r*sin(t)*v2[3]
	return (x, y, z)
end

# ╔═╡ f55bf207-fad4-44b1-b5d9-d7efe686bf42
"""Given 3-D orientation vector `o`, return orthonormal vectors
   `v1`, `v2` that span the plane to which `o` is normal."""
function normals(o)
	ex = [1., 0., 0.]; ey = [0., 1., 0.]; ez = [0., 0., 1.]
	ox = o[1]; oy = o[2]; oz = o[3]
	if all(iszero, o)
		v1 = ey
	elseif (ox == 0) && (oy == 0)
		v1 = sign(oz)*ey
	elseif (ox == 0) && (oz == 0)
		v1 = -sign(oy)*ex
	elseif (oy == 0) && (oz == 0)
		v1 = sign(ox)*ey
	else
#		if (oz > 0)
#	    	v1 = [-sign(ox)*oy/ox, sign(ox), 0]
#		else
#			v1 = [oy/ox, -1, 0]
#		end
		v1 = [ox == 0 ? 0 : -sign(ox)*oy/ox, sign(ox), 0]
	end
	v2 = cross(collect(o), v1)
	return (v1./norm(v1), v2./norm(v2))
end

# ╔═╡ 5cdd317a-de26-4093-8651-615bcb46ffa9
let
	c = [cx, cy, cz]; ox, oy, oz = sin(θ)*cos(ρ), sin(θ)*sin(ρ), cos(θ)
	o_ = [ox, oy, oz]
	o = 0.35 .* o_ ./ norm(o_)
	v1, v2 = normals(o)
	v1p = 0.35 .* v1; v2p = 0.35 .* v2;
	cir = stack(t -> paramcircle(c, r, v1, v2, t), range(0, 2π, 20), dims=1)
	@splot(:unitranges, {xyplane = "at 0"},
	       cx, cy, cz, ox, oy, oz, "w vectors lc 'black'")
	splot!(cx, cy, cz, v1p[1], v1p[2], v1p[3], "w vectors lc 'blue'")
	splot!(cx, cy, cz, v2p[1], v2p[2], v2p[3], "w vectors lc 'dark-green'")
	splot!(cir[:,1], cir[:,2], cir[:,3], "lc 'black'")
	cr = cross(v1, v2)
	splot!(cx, cy, cz, cr[1], cr[2], cr[3], "w vectors lc 'red'")
end

# ╔═╡ f4334764-5ada-424d-a0eb-8a9f7ee55c32
"""Central diff of `f` at `t` with step `h = 1e-6`"""
function cendiff(f, t, h = 1e-6)
	(f(t.+h/2) .- f(t.-h/2))./h
end

# ╔═╡ 398a6f8b-b783-4a38-82c9-b01012b347d4
let ft = ft
	N = 16 # number of circles to draw
	#c = [c2x, c2y, c2z] # torus center
	#ox, oy, oz = sin(θt)*cos(ρt), sin(θt)*sin(ρt), cos(θt)
	#o_ = [ox, oy, oz]
	#o = 0.2 .* o_ ./ norm(o_)
	#v1, v2 = normals(o)
	c = [0,0,0]; v1 = [1,0,0]; v2 = [0,1,0]
	pc(t) = paramcircle(c, rM, v1, v2, t)  # torus core
	cir = stack(pc, range(0, 2π, 20), dims=1)
	@splot(ft, :notics, :labels, {view=(60,30), view = "equal xy", ranges = (-3,3), xyplane = "at 0"}, cir[:,1], cir[:,2], cir[:,3])
	# center of each circle in the frame
	pcenters = range(0, 2π-2π/N, N)
	centers = [paramcircle(c, rM, v1, v2, t) for t in pcenters]
	for n in 1:N
		# orientation of each circle -- tangent to torus core
		oc = cendiff(pc, pcenters[n])
		n1, n2 = normals(oc); #display((oc, n1,n2))
		d = stack(t -> paramcircle(centers[n], rm, n1, n2, t), range(0,2π,10), dims=1)
		# plots
		splot!(ft, d[:,1], d[:,2], d[:,3], "lc 'black'")
		#splot!(ft, d[1,1], d[1,2], d[1,3], "w p pt '0'")
		#splot!(ft, d[3,1], d[3,2], d[3,3], "w p pt '3'")
		#splot!(ft, d[:,1], d[:,2], d[:,3], "lc 'black'")
		#splot!(ft, centers[n][1], centers[n][2], centers[n][3], centers[n][1]+oc[1], centers[n][2]+oc[2], centers[n][3]+oc[3], "w vectors lc 'green'")
	end
	ft
end

# ╔═╡ d25d04f9-c8c9-4b25-af01-1b67b4c1999f
let ft = ft
	res = 64 # points per circle
	N = 64 # number of circles to draw
	c = [c2x, c2y, c2z] # torus center
	ox, oy, oz = sin(θ)*cos(ρ), sin(θ)*sin(ρ), cos(θ) # torus orientation
	o_ = [ox, oy, oz]
	o = 0.2 .* o_ ./ norm(o_)
	v1, v2 = normals(o)
	pc(t) = paramcircle(c, rM, v1, v2, t)  # torus core
	cir = stack(pc, range(0, 2π, res), dims=1)
	# center of each circle in the frame
	pcenters = range(0, 2π, N)
	centers = [paramcircle(c, rM, v1, v2, t) for t in pcenters]
	x = zeros(res, N); y = zeros(res, N); z = zeros(res, N)
	for n in 1:N
		# orientation of each circle -- tangent to torus core
		oc = cendiff(pc, pcenters[n])
		n1, n2 = normals(oc)
		d = stack(t -> paramcircle(centers[n], rm, n1, n2, t), range(0,2π,res), dims=1)
		x[:,n] .= d[:,1]; y[:,n] .= d[:,2]; z[:,n] .= d[:,3]
	end
	@splot(ft, {pm3d = "depthorder", pm3d = "lighting", ranges=(-3,3),
	            hidden3d, cbrange = (-rm,rm),
	            palette = :plasma,
	            xyplane = "at 0",
	            colorbox = false}, :notics,
	            x, y, z, "w pm3d fillcolor 'dark-turquoise'")
end

# ╔═╡ e6c5661f-c864-4834-9ac5-1fc1b799bed0
""" torus

Calculate torus coordinates."""
function torus(c, θx, θy, θz, rM, rm, N, n)
	# step 1: calculate a torus in the origin
	x, y, z = torus(rM, rm, N, n)
	# step 2: calculate rotation matrices
	Rx = [1 0      0      ;
	      0 cos(θx) -sin(θx);
	      0 sin(θx)  cos(θx)]
	Ry = [ cos(θy) 0 sin(θy);
	       0      1 0     ;
	      -sin(θy) 0 cos(θy)]
	Rz = [cos(θz) -sin(θz) 0;
	      sin(θz)  cos(θz) 0;
	      0       0      1]
	R = Rz*Ry*Rx
	# step 3: rotate and translate each torus point
	p = zeros(3); q = zeros(3)
	for col in 1:N
		for row = 1:n
			p[1] = x[row, col]; p[2] = y[row, col]; p[3] = z[row, col]
			q = R*p;
			x[row, col] = q[1] + c[1]
			y[row, col] = q[2] + c[2]
			z[row, col] = q[3] + c[3]
		end
	end
	x, y, z
end

# ╔═╡ 1a407189-602e-4f79-9c68-8c0ec9527336
function torus(rM, rm, N, n)
	c = (0, 0, 0)
	v1, v2 = normals([0, 0, 1])
	# calculate torus core
	core(t) = paramcircle(c, rM, v1, v2, t)
	# find center of each torus slice
	pcenters = range(0, 2π, N)
	centers = [paramcircle(c, rM, v1, v2, t) for t in range(0, 2π, N)]
	x = zeros(n, N); y = zeros(n, N); z = zeros(n, N)
	d = zeros(n, 3)
	for k in 1:N
		# orientation of each circle -- tangent to torus core
		oc = cendiff(core, pcenters[k])
		n1, n2 = normals(oc)
		d .= stack(t -> paramcircle(centers[k], rm, n1, n2, t), range(0, 2π, n), dims = 1)
		x[:,k] .= d[:,1]; y[:,k] .= d[:,2]; z[:,k] .= d[:,3]
	end
	x, y, z
end

# ╔═╡ 45904d7b-3b2e-411d-8715-372220b5cd00
let
	all(iszero, (θx, θy, θz)) && (θz = 1.0)
	c = [c3x, c3y, c3z] # torus center
	x, y, z = torus(c, θx, θy, θz, rM, rm, 32, 32)
	splot("set xrange [-3:3]", "set yrange [-3:3]", "set zrange [-2:2]", :labels, "set pm3d depthorder", "set view 60,30", "set view equal xyz", "unset colorbox", "set pm3d lighting", x, y, z, "w pm3d fillcolor 'dark-turquoise'")
end

# ╔═╡ 6b476e91-aa7d-48ad-8cee-00630818238a
let
	c1 = [0,0,0]; x1 = 0; y1 = 0; z1 = 1; rM1 = 1; rm1 = 0.4;
	c2 = [1,0,0]; x2 = π/2; y2 = 0; z2 = 0; rM2 = 1; rm2 = 0.4;
	t1x, t1y, t1z = torus(c1, x1, y1, z1, rM1, rm1, 128, 128)
	t2x, t2y, t2z = torus(c2, x2, y2, z2, rM2, rm2, 128, 128)
	@splot(fti, {pm3d = "depthorder",
	             pm3d = "lighting",
	             tics = false,
	             colorbox = false,
	             view = "equal xyz",
	             view = (40, 20, 2)},
	            t1x, t1y, t1z, "w pm3d fillcolor 'dark-turquoise'")
	splot!(fti, t2x, t2y, t2z, "w pm3d fillcolor 'salmon'")
end

# ╔═╡ Cell order:
# ╟─05614214-fb38-4170-acfe-66b90b88c283
# ╠═4bd21a1f-900c-4837-b121-6e708ed9e178
# ╠═4a857a54-37f5-45d5-a715-95614ee569fe
# ╠═fd4dbf2c-3e9d-4a9e-8d45-0976c6fbd46c
# ╠═2fd048bc-2e87-490a-afc2-5c216d260e77
# ╠═4ccbcb36-2fb7-495a-ac80-3d4eab0f4471
# ╠═8fa8505a-98c8-46bf-a716-dba45626b98a
# ╠═a87cb7e3-18e4-49d3-a8db-31b7bbeacae0
# ╟─65a53ffa-c8c0-448b-957a-ea9c55928057
# ╟─053a7600-c582-4498-a848-e704fc1dd927
# ╠═5cdd317a-de26-4093-8651-615bcb46ffa9
# ╟─3480c76e-a643-4856-a51a-a4b621c7b545
# ╟─e7906ae5-e460-4d28-af8b-948415310d3d
# ╠═398a6f8b-b783-4a38-82c9-b01012b347d4
# ╟─036ae8fa-e6ba-4d06-94f9-c64c7b87507f
# ╟─1de39361-2264-4bdd-8694-462d41436a81
# ╠═d25d04f9-c8c9-4b25-af01-1b67b4c1999f
# ╟─4a0cdeda-1d93-4be9-8e79-e1510a9fe1e7
# ╟─07294d8b-b01c-4528-8217-0572466f9eaa
# ╠═45904d7b-3b2e-411d-8715-372220b5cd00
# ╟─7e89c619-c951-45eb-adfc-8e91f42d7e60
# ╠═6b476e91-aa7d-48ad-8cee-00630818238a
# ╟─e47bb743-75ba-427d-9301-a15cea857be3
# ╟─22941298-cc85-45d1-9fc7-96b2a1e6d863
# ╟─9d71d2ee-c194-49cf-ab41-c99500d36298
# ╟─f55bf207-fad4-44b1-b5d9-d7efe686bf42
# ╟─f4334764-5ada-424d-a0eb-8a9f7ee55c32
# ╟─e6c5661f-c864-4834-9ac5-1fc1b799bed0
# ╟─1a407189-602e-4f79-9c68-8c0ec9527336
