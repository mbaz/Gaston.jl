### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ 5ce01cd6-06d4-11ee-001b-05a54220a333
# ╠═╡ show_logs = false
begin
	using Revise
	import Pkg
    Pkg.develop(path="/home/miguel/rcs/jdev/Gaston")
	using Gaston
	import Gaston: TimeSeries, TSBundle, PlotObject, GASTON_VERSION
end

# ╔═╡ d3c15655-800e-4911-b3f5-ba88574c4924
using SinusoidalRegressions

# ╔═╡ 593b76ea-a677-490c-90fc-20e6a4bb6e9b
GASTON_VERSION

# ╔═╡ 1f816d21-1d61-4d1d-8ba8-6c42d4e699a7
begin
	param_exact = MixedLinSinModel(f = 4.1, DC = 0.2, m = 1, Q = -0.75, I = 0.8)
	N = 60
	x = range(0, length = N, step = 1/N)
	data_exact = param_exact(x)
	data = data_exact .+ 0.2*randn(N)  # noisy data
	problem = MixedLinSin5Problem(x, data)
	algorithm = IntegralEquations()
	fit = sinfit(problem, algorithm)
end

# ╔═╡ a4fad770-0a63-4ed1-820f-58971296315d
function Gaston.convert_args(x, data, fit::SRModel)
	ts1 = TimeSeries(collect(x), data, pl = "w p pt 16 ps 1.5 lc 'red' title 'data'")
	ts2 = TimeSeries(collect(x), fit.(x), pl = "w l lc 'blue' title 'fit'")
	settings = """set key box outside right top
	              set grid
	              set xlabel 'time'
	              set ylabel 'amplitude'"""
	PlotObject( TSBundle(ts1, ts2; settings) )
end

# ╔═╡ bad0d6b6-582c-4ab5-bccf-8dc12e5686fd
plot(x, data, fit)

# ╔═╡ 7597c0cb-4f09-4485-b648-70d019345318
function Gaston.convert_args(x, fit::SRModel)
	ts1 = TimeSeries(collect(x), fit.(x))
	PlotObject( TSBundle(ts1) )
end

# ╔═╡ 09d5e643-abbc-46b7-86b3-c7f7137e9c63
plot(x, fit)

# ╔═╡ Cell order:
# ╠═5ce01cd6-06d4-11ee-001b-05a54220a333
# ╠═593b76ea-a677-490c-90fc-20e6a4bb6e9b
# ╠═d3c15655-800e-4911-b3f5-ba88574c4924
# ╠═1f816d21-1d61-4d1d-8ba8-6c42d4e699a7
# ╠═a4fad770-0a63-4ed1-820f-58971296315d
# ╠═bad0d6b6-582c-4ab5-bccf-8dc12e5686fd
# ╠═7597c0cb-4f09-4485-b648-70d019345318
# ╠═09d5e643-abbc-46b7-86b3-c7f7137e9c63
