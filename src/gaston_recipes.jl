### 2-D Recipes

## Scatter plots
# real vectors
"""
    scatter(x, y [, axes] [, curve] ; args...) -> Gaston.Figure

Create a scatter plot with vectors `x` and `y`. `axes` and `curve` specify the
axes and curve configurations, respectively.

    scatter(c, args...) -> Gaston.Figure

If `c` is a complex vector, Create a scatter plot of the real and imaginary
parts of `c`.
"""
scatter(x, y ; args...) = plot(x, y, w=:points ; args...)
scatter(x, y, a::Axes ; args...) = plot(x, y, nothing, a, w=:points ; args...)

# complex vectors
scatter(y::ComplexCoord ; args...) = scatter(real(y), imag(y) ; args...)
scatter(y::ComplexCoord, a::Axes ; args...) = scatter(real(y), imag(y), a ; args...)

# add curves
"""
    scatter!(...) -> Gaston.Figure

Add a new scatter plot to an existing plot.
"""
scatter!(x, y ; args...) = plot!(x, y, ps=:points ; args...)
scatter!(y::ComplexCoord ; args...) = scatter!(real(y), imag(y); args...)

## Stem plots
"""
    stem(x, y, onlyimpulses=false, [,axes] [, curve], args...) -> Gaston.Figure

Create a stem plot using `x` and `y`. If `onlyimpulses` is true, then the
conventional circles indicating each sample are not drawn.

    stem(x, f::Function, onlyimpulses=false, [,axes] [, curve], args...) -> Gaston.Figure

Use `y = f.(x)`
"""
function stem(x, y, a::Axes = Axes() ; onlyimpulses=false, args...)
    p = plot(x, y, nothing, a ; w=:impulses, lc=:blue, lw=1.25, args...)
    onlyimpulses || (p = plot!(x, y ; w=:points, lc=:blue, pt="ecircle", ps=1.5, args...))
    return p
end
stem(y ; args...) = stem(1:length(y), y ; args...)
stem(y, a::Axes ; args...) = stem(1:length(y), y, a ; args...)
stem(x, f::Function ; args...) = stem( x, f.(x) ; args...)
stem(x, f::Function, a::Axes ; args...) = stem( x, f.(x), a ; args...)

## Bar plots
"""
    bar([x,] y, [axes,] args...) -> Gaston.Figure

Generate a bar plot with axes configuration `axes`.
"""
function bar(x, y, a::Axes = Axes() ; args...)
    plot(x, y, nothing,
         merge(Axes(boxwidth="0.8 relative", style="fill solid 0.5"), a),
         w=:boxes ; args...)
end
bar(y ; args...) = bar(1:length(y), y ; args...)
bar(y, a::Axes ; args...) = bar(1:length(y), y, a ; args...)

## Histograms
"""
    histogram(data, [axes,] bins=10, norm=1.0, args...) -> Gaston.Figure

Plot a histogram of `data`. `bins` specifies the number of bins (default 10),
and the histogram area is normalized to `norm` (default 1.0).
"""
function histogram(data, a::Axes = Axes() ; bins::Int=10, norm::Real=1.0, args...)
    # validation
    bins < 1 && throw(DomainError(bins, "at least one bin is required"))
    norm < 0 && throw(DomainError(norm, "norm must be a positive number."))
    # calculate data
    x, y = hist(data,bins)
    # make area under histogram equal to norm
    y = norm*y/(step(x)*sum(y))
    # plot
    bar(x, y, a; args...)
end

## Images
"""
    imagesc([x,] [y,] z, [axes,] args...) -> Gaston.Figure

Plot an image given by array `z`. If the array is a matrix, a grayscale image
is assumed. If the array is three-dimensional, an rgbimage is assumed, with
`z[1,:,:]` the red channel, `z[2,:,:]` the blue channel, and `z[3,:,:]` the
blue channel.
"""
function imagesc(x, y, z, a::Axes = Axes() ; args...)
    ps = "image"
    ndims(z) == 3 && (ps = "rgbimage")
    plot(x, y, z, a, w=ps ; args...)
end
# grayscale
function imagesc(z::Matrix, a::Axes = Axes() ; args...)
    imagesc(1:size(z)[2], 1:size(z)[1], z, a ; args...)
end
# rgb
function imagesc(z::AbstractArray{<:Real,3}, a::Axes = Axes() ; args...)
    imagesc(1:size(z)[3], 1:size(z)[2], z, a ; args...)
end

### 3-D recipes

## Surfaces
"""
    surf([x,] [y,] z, [axes,] args...)-> Gaston.Figure

Plot the surface specified by `z` with axes specification `axes`.

    surf(x, y f::Function, args...)-> Gaston.Figure

Plot the surface `f.(x,y)`.
"""
surf(x, y, z, a::Axes = Axes() ; args...) = plot(x, y, z, a, dims=3 ; args...)
surf!(x, y, z ; args...) = plot!(x, y, z, dims=3 ; args...)
# function
function surf(x, y, f::Function, a::Axes = Axes() ; args...)
    plot(x, y, meshgrid(x, y, f), a, dims=3 ; args...)
end

"""
    surf!(...)

Add a surface to an existing figure.
"""
surf!(x, y, f::Function ; args...) = plot!(x, y, meshgrid(x, y, f), dims=3 ; args...)
# matrix
function surf(z::Matrix, a::Axes = Axes() ; args...)
    surf(1:size(z)[2], 1:size(z)[1], z, a, dims=3 ; args...)
end
surf!(z::Matrix ; args...) = surf!(1:size(z)[2], 1:size(z)[1], z, dims=3 ; args...)

## 3-D scatter
"""
    scatter3(x, y, z, [axes,] [curve,], args...) -> Gaston.Figure

Create a 3-D scatter plot with vectors `x`, `y` and `z`. `axes` and `curve`
specify the axes and curve configurations, respectively.

    scatter3(x, f1::Function, f2::Function, args...) -> Gaston.Figure

Create the scatter plot of `x`, `f1.(x)`, and `f2.(x)`.
"""
function scatter3(x, y, z, a::Axes = Axes() ; args...)
    surf(x, y, z, a, w=:points ; args...)
end
scatter3!(x, y, z ; args...) = surf!(x, y, z, w=:points ; args...)
# functions
function scatter3(x, f1::Function, f2::Function, a::Axes = Axes() ; args...)
    scatter3(x, f1.(x), f2.(x), a, dims=3 ; args...)
end
""""
    scatter3!(...) -> Gaston.Figure

Add a new scatter plot to an existing plot.
"""
function scatter3!(x, f1::Function, f2::Function ; args...)
    scatter3!(x, f1.(x), f2.(x), dims=3 ; args...)
end

# 3-D contour plots
"""
    contour([x,] [y,] z::Matrix, labels = true, [axes,] args...) -> Gaston.Figure

Plot the contour lines given by the surface `z`. If `labels = false`, no labels
are included in the plot.

    contour(x, y, f::Function, args...) -> Gaston.Figure

Plot the contours of the surface `f.(x,y)`.
"""
function contour(x, y, z, a::Axes = Axes() ; labels=true, args...)
    conaxes = Axes(key = false,
                   view = "map",
                   contour = "base",
                   surface = false,
                   cntrlabel = "font '7'",
                   cntrparam = "levels 10"
                  )
    p = surf(x, y, z, merge(conaxes, a) ; args...)
    labels && (p = surf!(x, y, z ; plotstyle=:labels))
    return p
end
contour(x, y, f::Function ; args...) = contour(x, y, meshgrid(x, y, f) ; args...)
contour(z::Matrix ; args...) = contour(1:size(z)[2], 1:size(z)[1], z ; args...)

# 3-D heatmaps
"""
    heatmap(x, y, z::Matrix, [axes,] args...)

Plot the heatmap of the surface specified by `z`.
"""
function heatmap(x, y, z, a::Axes = Axes(); args...)
    surf(x, y, z, merge(Axes(view="map"), a), w=:pm3d ; args...)
end
