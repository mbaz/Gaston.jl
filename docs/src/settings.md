```@meta
Author = "Miguel Bazdresch"
```

# Settings and Configuration

## Passing data to plot commands

Plot commands take data in the following formats.

## Setting the terminal

In gnuplot parlance, the "terminal" is the device that renders a plot. While the terminal can be configured in gnuplot's initialization file (e.g. `~/.gnuplot`), it is *highly* recommended to configure the terminal in Gaston, unless you know very well what you are doing.

To set the terminal, run `set(terminal="term name")`. The default terminal is `qt`.

Advanced users may want to further refine their terminal configuration. To do this, set the configuration option `termopts`. This defines a string that is passed to gnuplot at the end of the `set term` line. For example, if you need a non-enhanced terminal, run `set(termopts="noenhanced").

The available terminals for plotting are:

| Terminal | Purpose |
| :------: | :------ |
| `qt` | gnuplot's most advanced graphical terminal |
| `wxt` | older, also very capable graphical terminal |
| `aqua` | for Apple users |
| `x11` | barebones, fallback graphical terminal |
| `dumb` | plot to the REPL using ASCII |
| `sixelgd` | plot to the REPL using sixels |

For more information on plotting with sixels, [see this discourse thread](https://discourse.julialang.org/t/plots-in-the-terminal-with-sixel/22503).

Note that, in Jupyter and Juno, the terminal is locked to a special mode that outputs plots as SVG text. The terminal cannot be changed in these environments.

### Saving figures

The terminals available for printing (saving) are `pdf`, `eps`, `svg`, `png` and `gif`. The following options, if set, will be used by `printfigure` when saving a plot:

| Property | Purpose | Allowed values | Default | `set`able |
| :------- | :------ | :------------- | :-----: | :-------: |
| print_term | Terminal to use for saving | See above | `pdf` | ✓ |
| print_font | Font to use when saving | `"Font,size"` | `""` | ✓ |
| print_size | Size of saved figure | `"x,y"` | `""` | ✓ |
| print_linewidth | Linewidth of all lines | A number in quotes, e.g. `"2"` | `""` | ✓ |
| print_background | Background color | A valid color, e.g. `"cyan"` | `""` | ✓ |
| print_outputfile | Output file name | Any string | None | ✗ |

## Setting a figure's properties

All settings are applied in the following order, in increasing order of precedence:

1. Gnuplot init file
2. Options set with `set`
3. Options given in a plot command

Options set with the `set` command affect all future plots. Options given in a plot command affect only that plot.

There are three kinds of configuration options: axes properties, curve properties, and print (save) properties. Axes properties affect the entire figure; curve properties are individual for each plot in the figure. Print properties only affect saving a figure to a file.

For many properties, the default value can be changed using `set(property=value)`. When a property is set to `""`, gnuplot will use its default value (possibly set in its initialization file).

Gaston's configuration can be reset by running `set(reset=true)`.

Except when indicated otherwise, all values are strings.

See [gnuplot's documentation](http://www.gnuplot.info/docs_5.2/Gnuplot_5.2.pdf) for details of property options and syntax.

## Supported axes properties

You may configure the following axes properties:

| Property | Purpose | Allowed values | Default | `set`able |
| :------- | :------ | :------------- | :-----: | :-------: |
| `title`    | Plot title | Any string  | `""` | ✗ |
| `xlabel`   | X axis label | Any string | `""` | ✗ |
| `ylabel`   | Y axis label | Any string | `""` | ✗ |
| `zlabel`   | Z axis label | Any string | `""` | ✗ |
| `axis`     | Change axis scaling | `"semilogy"`, `"semilogx"`, or `"loglog"` | `""` | ✓ |
| `grid`     | Show a grid | `"on"` or a valid grid setting, e.g. `"noxtics"` | `""` | ✓ |
| `{x,y,z}range` | X axis limits | A valid range, e.g. `"[-3:2]"` | `""` | ✓ |
| `keyoptions` | Control key (legends) placement | A valid key setting, e.g. `"box top left"`| `""` | ✓ |
| `fillstyle` | Style for filled curves | A valid fill style, e.g. `"solid 0.5"` | `""` | ✓ |
| `boxwidth` | Box witdh in box plots  | A valid boxwidth setting, e.g. `"0.5 relative"` | `""`  | ✓ |
| `{x,y,z}zeroaxis` | Draw a line along the selected axis| `"on"` or a valid zeroaxis setting | `""` | ✓ |
| `palette`   | Colors for `pm3d` style | A valid palette name, e.g. `"gray"` | `""` | ✓ |
| `onlyimpulses` | Configure `stem` plots | `true` or `false` | `false` | ✓ |
| `font` | Plot font | A valid font spec, e.g. `"Consolas,10"` | `""` | ✓ |
| `size` | Plot size | A valid size spec, e.g. `"800,600"` | `""` | ✓ |
| `linewidth` | Linewidth multiplier | A number in quotes, e.g. `"3"` | `""` | ✓ |
| `background` | Plot background color | A valid color, e.g. `"cyan"` | `""` | ✓ |


## Supported curve properties

You may configure the following curve properties:

| Property | Purpose | Allowed values | Default | `set`able |
| :------- | :------ | :------------- | :-----: | :-------: |
| `"plotstyle"` | Select plot style | One of "`lines`", `"linespoints"`, `"points"`, `"impulses"`, `"boxes"`, `"errorlines"`, `"errorbars"`, `"dots"`, `"steps"`, `"fsteps"`, `"fillsteps"`, `"financebars"` | `""` | ✓ |
| `legend` | Curve description | Any string | `""` | ✓ |
| `linecolor` | Line color | A valid color, e.g. "red" | `""` | ✓ |
| `linewidth` | Line width | A number in quotes, e.g. `"2"` | `""` | ✓ |
| `linestyle` | Select more complex lines | A string containing a combination of `-`, `.`, `_` and `<space>`; empty string plots solid lines | `""` | ✓ |
| `pointsize` | Marker size | A number in quotes, e.g. `"2"` | `""` | ✓ |
| `pointtype` | Marker style | One of `""`, `+`, `x`, `*`, `esquare`, `fsquare`, `ecircle`, `fcircle`, `etrianup`, `ftrianup`, `etriandn`, `ftriandn`, `edmd`, `fdmd` | `""` | ✓ |
| `fillcolor` | Color for filled curves | A valid color, e.g. "red" | `""` | ✓ |
| `fillstyle` | Style for filled curves | A valid fill style, e.g. `"solid 0.5"` | `""` | ✓ |
