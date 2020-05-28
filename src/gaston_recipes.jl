### 2-D Recipes

## Scatter plots
# real vectors
scatter(x, y ; args...) = plot(x, y, w=:points ; args...)
scatter(x, y, a::Axis ; args...) = plot(x, y, nothing, a, w=:points ; args...)
# complex vectors
scatter(y::ComplexCoord ; args...) = scatter(real(y), imag(y) ; args...)
scatter(y::ComplexCoord, a::Axis ; args...) = scatter(real(y), imag(y), a ; args...)
# add curves
scatter!(x, y ; args...) = plot!(x, y, ps=:points ; args...)
scatter!(y::ComplexCoord ; args...) = scatter!(real(y), imag(y); args...)

## Stem plots
function stem(x, y, a::Axis = Axis() ; onlyimpulses=false, args...)
    p = plot(x, y, nothing, a ; w=:impulses, lc=:blue, lw=1.25, args...)
    onlyimpulses || (p = plot!(x, y ; w=:points, lc=:blue, pt="ecircle", pz=1.5, args...))
    return p
end
stem(y ; args...) = stem(1:length(y), y ; args...)
stem(y, a::Axis ; args...) = stem(1:length(y), y, a ; args...)
stem(x, f::Function ; args...) = stem( x, f.(x) ; args...)
stem(x, f::Function, a::Axis ; args...) = stem( x, f.(x), a ; args...)

## Bar plots
function bar(x, y, a::Axis = Axis() ; args...)
    plot(x, y, nothing,
         merge(a, Axis(boxwidth="0.8 relative", style="fill solid 0.5")),
         w=:boxes ; args...)
end
bar(y ; args...) = bar(1:length(y), y ; args...)
bar(y, a::Axis ; args...) = bar(1:length(y), y, a ; args...)

## Histograms
function histogram(data, a::Axis = Axis() ; bins::Int=10, norm::Real=1.0, args...)
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
function imagesc(x, y, z, a::Axis = Axis() ; args...)
    ps = "image"
    ndims(z) == 3 && (ps = "rgbimage")
    plot(x, y, z, a, w=ps ; args...)
end
# grayscale
function imagesc(z::Matrix, a::Axis = Axis() ; args...)
    imagesc(1:size(z)[2], 1:size(z)[1], z, a ; args...)
end
# rgb
function imagesc(z::AbstractArray{<:Real,3}, a::Axis = axis() ; args...)
    imagesc(1:size(z)[3], 1:size(z)[2], z, a ; args...)
end

### 3-D recipes

## Surfaces
surf(x, y, z, a::Axis = Axis() ; args...) = plot(x, y, z, a, dims=3 ; args...)
surf!(x, y, z ; args...) = plot!(x, y, z, dims=3 ; args...)
# function
function surf(x, y, f::Function, a::Axis = Axis() ; args...)
    plot(x, y, meshgrid(x, y, f), a, dims=3 ; args...)
end
surf!(x, y, f::Function ; args...) = plot!(x, y, meshgrid(x, y, f), dims=3 ; args...)
# matrix
function surf(z::Matrix, a::Axis = Axis() ; args...)
    surf(1:size(z)[2], 1:size(z)[1], z, a, dims=3 ; args...)
end
surf!(z::Matrix ; args...) = surf!(1:size(z)[2], 1:size(z)[1], z, dims=3 ; args...)

## 3-D scatter
function scatter3(x, y, z, a::Axis = Axis() ; args...)
    surf(x, y, z, a, w=:points ; args...)
end
scatter3!(x, y, z ; args...) = surf!(x, y, z, w=:points ; args...)
# functions
function scatter3(x, f1::Function, f2::Function, a::Axis = Axis() ; args...)
    scatter3(x, f1.(x), f2.(x), a, dims=3 ; args...)
end
function scatter3!(x, f1::Function, f2::Function ; args...)
    scatter3!(x, f1.(x), f2.(x), dims=3 ; args...)
end

# 3-D contour plots
function contour(x, y, z, a::Axis = Axis() ; labels=true, args...)
    conaxis = Axis(key = false,
                   view = "map",
                   contour = "base",
                   surface = false,
                   cntrlabel = "font '7'",
                   cntrparam = "levels 10"
                  )
    p = surf(x, y, z, merge(conaxis, a) ; args...)
    labels && (p = surf!(x, y, z ; plotstyle=:labels))
    return p
end
contour(x, y, f::Function ; args...) = contour(x, y, meshgrid(x, y, f) ; args...)
contour(z::Matrix ; args...) = contour(1:size(z)[2], 1:size(z)[1], z ; args...)

# 3-D heatmaps
function heatmap(x, y, z, a::Axis = Axis(); args...)
    surf(x, y, z, merge(a, Axis(view="map")), w=:pm3d ; args...)
end
