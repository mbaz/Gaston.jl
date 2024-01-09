# Themes in use are stored in this dictionary.
# Each theme is identified by a name.

# settings themes
sthemes = @gpkw Dict(
    :none => Pair[],

    :notics => {tics = false},
    :labels => {xlabel = "'x'", ylabel = "'y'", zlabel = "'z'"},
    :unitranges => {xrange = (-1,1), yrange = (-1,1), zrange = (-1,1)},
    :boxplot => {boxwidth = "0.8 relative", style = "fill solid 0.5"},
    :histplot => {boxwidth = "0.8 relative", style = "fill solid 0.5", yrange = "[0:*]"},
    :imagesc => {yrange = "reverse"},
    :wireframe => {hidden3d},
    :wiresurf => {hidden3d, pm3d = "implicit depthorder border lc 'black' lw 0.3"},
    :heatmap => {view = "map"},
    :contour => {
        key       =  false,
        view      = "map",
        contour   = "base",
        surface   = false,
        cntrlabel = "font ',7'",
        cntrparam = "levels auto 10",
    },
    :contourproj => {
        hidden3d,
        key       = false,
        contour   = "base",
        cntrlabel = "font ',7'",
        cntrparam = "levels auto 10"
    },
    :hist_1d => {boxwidth = "0.8 relative", style = "fill solid 0.5", yrange = "[0:*]"},
    :scatter3 => {border = "4095",
                  grid = "xtics ytics ztics vertical",
                  xyplane = "relative 0.05"},
)

# plotline themes
pthemes = @gpkw Dict(
    :none => Pair[],

    :scatter => {with = "points", pointtype = :fcircle, pointsize = 1.5},
    :impulses => {with = "impulses"},
    :stem => {with = "points", pointtype = :ecircle, pointsize = 2},
    :box => {with = "boxes"},
    :boxerror => {with = "boxerrorbars"},
    :boxxyerror => {with = "boxxyerror"},
    :image => {with = "image"},
    :rgbimage => {with = "rgbimage"},
    :horhist => {u = "2:1:(0):2:(\$0-0.5):(\$0+0.5)", with = "boxxyerror"},
    :pm3d => {with = "pm3d"},
    :labels => {with = "labels"},
)
