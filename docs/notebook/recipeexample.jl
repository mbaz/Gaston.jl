### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ 1d1f93c0-07a5-11ee-1f1d-4b090315c1e4
# ╠═╡ show_logs = false
begin
	using Revise
	import Pkg
    Pkg.develop(path="/home/miguel/rcs/jdev/Gaston")
	using Gaston
	import Gaston: TimeSeries, TSBundle, PlotObject, GASTON_VERSION
end

# ╔═╡ ad1527dc-d7b4-4d61-bf19-a8893da2d150
GASTON_VERSION

# ╔═╡ 369b7a9c-c86b-4d48-9f0c-27e5e13884b6
struct MyType end

# ╔═╡ 8d05783e-531f-43e9-9d15-4f56696bbcf5
function Gaston.convert_args(x::MyType)
	t1 = range(0, 1, 40)
	t2 = range(-5, 5, 50)
	z = Gaston.meshgrid(t2, t2, (x,y) -> cos(x)*cos(y))
	@options PlotObject(
		TSBundle(
			TimeSeries(1:10, rand(10)),
			settings = {title = qs"First Axis"}
		),
	    TSBundle(
			TimeSeries(t1, sin.(5t1), pl = {lc = qs"black"}),
	        TimeSeries(t1, cos.(5t1), pl = {w = "p", pt = 16}),
	        settings = {title = qs"Trig"}
		),
		TSBundle(
			TimeSeries(t2, t2, z, pl = {w = "pm3d"}, is3d = true),
			settings = {title = qs"3D",
			            tics = false,
						palette = (:matter, :reverse)}
		),
		TSBundle(
			TimeSeries(1:10, 1:10, rand(10,10), pl = "w image"),
			settings = {tics, title = false}
		),
		mp_settings = "title 'A Four-Axes Recipe' layout 2,2"
	)
end

# ╔═╡ 0ddd2d13-ec00-4d44-a72a-a75782e516fe
plot(MyType())

# ╔═╡ 40422d6a-2b70-4e3a-a516-7d513772e92d
function myplot(data::Vector{<:Complex}; kwargs...)
                    x = 1:length(data)
                    y1 = abs2.(data)
                    y2 = angle.(data)
                    Gaston.sthemes[:myplot1] = @options {grid, ylabel = qs"Magnitude"}
                    Gaston.sthemes[:myplot2] = @options {grid, ylabel = qs"Angle"}
                    Gaston.pthemes[:myplot1] = @options {w = "lp"}
                    Gaston.pthemes[:myplot2] = @options {w = "p", lc = "'black'"}
                    f = Figure(multiplot = "layout 2,1")
                    plot(f[1], x, y1, stheme = :myplot1, ptheme = :myplot1)
                    plot(f[2], x, y2, stheme = :myplot2, ptheme = :myplot2)
                    return f
                end

# ╔═╡ Cell order:
# ╠═1d1f93c0-07a5-11ee-1f1d-4b090315c1e4
# ╠═ad1527dc-d7b4-4d61-bf19-a8893da2d150
# ╠═369b7a9c-c86b-4d48-9f0c-27e5e13884b6
# ╠═8d05783e-531f-43e9-9d15-4f56696bbcf5
# ╠═0ddd2d13-ec00-4d44-a72a-a75782e516fe
# ╠═40422d6a-2b70-4e3a-a516-7d513772e92d
