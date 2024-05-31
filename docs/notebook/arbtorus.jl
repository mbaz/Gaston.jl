### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
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

### Plotting two interlocking torii

Let's start by loading Gaston and PlutoUI."

# ╔═╡ 4f534110-d4c6-44ce-b39c-b2b4d734fc46
Gaston.GASTON_VERSION

# ╔═╡ 8fa8505a-98c8-46bf-a716-dba45626b98a
PlutoUI.TableOfContents(title = "Contents")

# ╔═╡ 65a53ffa-c8c0-448b-957a-ea9c55928057
md"""### Step 1: plotting a 3-D circle

Consider a circle with center in $p \in \mathbb{R}^3$ on the plane defined by the orthonormal vectors $\mathbf{v}_1$ and $\mathbf{v}_2$. The parametric equation of this circle is

$[x, y, z] = p + r\cos(t)\mathbf{v}_1 + r\sin(t)\mathbf{v}_2.$

Let's test this out:
"""

# ╔═╡ 053a7600-c582-4498-a848-e704fc1dd927
md"""#### Center
cx: $(@bind cx Slider(-5:0.1:5, default = 0, show_value = true))
cy: $(@bind cy Slider(-5:0.1:5, default = 0, show_value = true))
cz: $(@bind cz Slider(-5:0.1:5, default = 0, show_value = true))
"""

# ╔═╡ 53251825-a648-4473-9139-a12dac820f2d
md"""#### Radius

Radius: $(@bind r Slider(0.1:0.1:3, default = 1, show_value = true))"""

# ╔═╡ 79594aea-ce7b-4f16-aa06-fd0b257199b2
md"""#### Orientation
θ: $(@bind θ Slider(0:0.05:π, default = 0, show_value = true))
ρ: $(@bind ρ Slider(0:0.05:2π, default = 0, show_value = true))
"""

# ╔═╡ 3480c76e-a643-4856-a51a-a4b621c7b545
md"""### Step 2: Plotting a donut frame

Let's draw the frame of a torus of major radius $r_M$ and minor radius $r_m$.

#### Radius"""

# ╔═╡ e7906ae5-e460-4d28-af8b-948415310d3d
md"rM $(@bind rM Slider(0.1:0.1:2, default = 1, show_value = true))
rm $(@bind rm Slider(0.1:0.1:1, default = 0.1, show_value = true))"

# ╔═╡ 1de39361-2264-4bdd-8694-462d41436a81
md"""#### Center
cx: $(@bind c2x Slider(-5:0.1:5, default = 0, show_value = true))
cy: $(@bind c2y Slider(-5:0.1:5, default = 0, show_value = true))
cz: $(@bind c2z Slider(-5:0.1:5, default = 0, show_value = true))
"""

# ╔═╡ 7b72f733-dcde-4114-b012-094b0748910e
md"""#### Orientation
θ: $(@bind θt Slider(0:0.05:π, default = 0, show_value = true))
ρ: $(@bind ρt Slider(0:0.05:π, default = 0, show_value = true))
"""

# ╔═╡ 036ae8fa-e6ba-4d06-94f9-c64c7b87507f
md"""### Step 3: Plotting the torus' surface"""

# ╔═╡ a87cb7e3-18e4-49d3-a8db-31b7bbeacae0
import LinearAlgebra: norm, cross, dot

# ╔═╡ 22941298-cc85-45d1-9fc7-96b2a1e6d863
begin
	ft = Figure("torus")
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
	display([ox,oy,oz]); o_ = [ox, oy, oz]
	o = 0.35 .* o_ ./ norm(o_); v1, v2 = normals(o)
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
	N = 9 # number of circles to draw
	c = [c2x, c2y, c2z] # torus center
	ox, oy, oz = sin(θt)*cos(ρt), sin(θt)*sin(ρt), cos(θt) # torus orientation
	o_ = [ox, oy, oz]
	o = 0.2 .* o_ ./ norm(o_)
	v1, v2 = normals(o)
	pc(t) = paramcircle(c, rM, v1, v2, t)  # torus core
	cir = stack(pc, range(0, 2π, 20), dims=1)
	@splot(ft, :notics, {ranges = (-3,3), xyplane = "at 0"}, cir[:,1], cir[:,2], cir[:,3])
	# center of each circle in the frame
	pcenters = range(0, 2π-2π/N, N)
	centers = [paramcircle(c, rM, v1, v2, t) for t in pcenters]
	for n in 1:N
		# orientation of each circle -- tangent to torus core
		oc = cendiff(pc, pcenters[n])
		n1, n2 = normals(oc)
		d = stack(t -> paramcircle(centers[n], rm, n1, n2, t), range(0,3π/2,10), dims=1)
		# plots
		#splot!(ft, d[:,1], d[:,2], d[:,3], "lc 'black'")
		splot!(ft, d[1,1], d[1,2], d[1,3], "w p pt '0'")
		splot!(ft, d[3,1], d[3,2], d[3,3], "w p pt '3'")
		splot!(ft, d[:,1], d[:,2], d[:,3], "lc 'black'")
		#splot!(ft, centers[n][1], centers[n][2], centers[n][3], centers[n][1]+oc[1], centers[n][2]+oc[2], centers[n][3]+oc[3], "w vectors lc 'green'")
	end
	ft
end

# ╔═╡ d25d04f9-c8c9-4b25-af01-1b67b4c1999f
let ft = ft
	res = 3 # points per circle
	N = 9 # number of circles to draw
	c = [c2x, c2y, c2z] # torus center
	ox, oy, oz = sin(θt)*cos(ρt), sin(θt)*sin(ρt), cos(θt) # torus orientation
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
		d = stack(t -> paramcircle(centers[n], rm, n1, n2, t), range(0,π,res), dims=1)
		x[:,n] .= d[:,1]; y[:,n] .= d[:,2]; z[:,n] .= d[:,3]
	end
	@splot(ft, :notics, {ranges=(-3,3),
	            hidden3d,
	            palette = :ice,
	            xyplane = "at 0",
	            colorbox = false},
	            x, y, z, "w l")
end

# ╔═╡ Cell order:
# ╟─05614214-fb38-4170-acfe-66b90b88c283
# ╠═4bd21a1f-900c-4837-b121-6e708ed9e178
# ╠═4a857a54-37f5-45d5-a715-95614ee569fe
# ╠═fd4dbf2c-3e9d-4a9e-8d45-0976c6fbd46c
# ╠═2fd048bc-2e87-490a-afc2-5c216d260e77
# ╠═4f534110-d4c6-44ce-b39c-b2b4d734fc46
# ╠═4ccbcb36-2fb7-495a-ac80-3d4eab0f4471
# ╠═8fa8505a-98c8-46bf-a716-dba45626b98a
# ╟─65a53ffa-c8c0-448b-957a-ea9c55928057
# ╠═053a7600-c582-4498-a848-e704fc1dd927
# ╟─53251825-a648-4473-9139-a12dac820f2d
# ╟─79594aea-ce7b-4f16-aa06-fd0b257199b2
# ╠═5cdd317a-de26-4093-8651-615bcb46ffa9
# ╟─3480c76e-a643-4856-a51a-a4b621c7b545
# ╟─e7906ae5-e460-4d28-af8b-948415310d3d
# ╟─1de39361-2264-4bdd-8694-462d41436a81
# ╟─7b72f733-dcde-4114-b012-094b0748910e
# ╟─398a6f8b-b783-4a38-82c9-b01012b347d4
# ╟─036ae8fa-e6ba-4d06-94f9-c64c7b87507f
# ╠═d25d04f9-c8c9-4b25-af01-1b67b4c1999f
# ╠═a87cb7e3-18e4-49d3-a8db-31b7bbeacae0
# ╠═22941298-cc85-45d1-9fc7-96b2a1e6d863
# ╟─9d71d2ee-c194-49cf-ab41-c99500d36298
# ╠═f55bf207-fad4-44b1-b5d9-d7efe686bf42
# ╟─f4334764-5ada-424d-a0eb-8a9f7ee55c32
