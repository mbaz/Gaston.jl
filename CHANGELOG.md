New in version 2
================

Gaston v2 is a breaking release. A
[migration guide](https://mbaz.github.io/Gaston.jl/v2/migrate.html) is available.

* A recipe system for plotting arbitrary Julia types.
  * Recipes can be written without depending on Gaston using a new package,
    GastonRecipes, which is very small, has only one dependency (`MacroTools`),
    and no exports.
* New, simpler but more flexible syntax.
  * Axis settings and curve appearance are distinguished by their position in the
    `plot` command (before and after data, respectively). Example:

    `plot("set grid", x, y, "linecolor 'blue'")`

  * `@plot` and `@splot` macros that take key-value arguments, as in:

    `@plot {title = Q"A Plot"} x y {with = "lp"}`

  * The string macro `Q_str` converts string `Q"A b"` to `"'A b'"`
  * The macro `@gpkw` allows any plot command to take key-value arguments:
    `@gpkw surf({grid}, x, y, z)`
  * Support for gnuplot datasets, including reading back data after plotting
    `with table`.
* Overhauled multiplot support.
  * Axes are placed by indexing a figure: `plot(f[2], x, y)` will place the plot
    as the second axis in figure `f`.
  * Curves can be pushed into axes and axes into figures arbitrarily.
  * `p1 = plot(...); p2 = plot(...); plot(p1, p2)` is also supported (creates a
    multiplot with figures `p1` and `p2`.
  * Automatic layout keeps a square aspect ratio, or user may take complete
    control over layout.
* Every figure is backed up by a separate gnuplot process.
* Simpler interace for saving plots: `save([figure,], filename, terminal)`.
* Better support for animations in notebooks.
* Support for themes.
  * More than 20 pre-defined plotting styles (`surf`, `heatmap`, `histogram`, etc)
    based on built-in themes.
* Simpler configuration, by changing values of a few `Gaston.config` fields.
* Re-written [documentation](https://mbaz.github.io/Gaston.jl/v2/).

# version 1.1.2

* Bug fixes

# version 1.1.1

* Bug fixes

# version 1.1

* Require Julia 1.6

# version 1.0.6

* Bug fixes

# version 1.0.5

* Bug fixes

# version 1.0.4

* Bug fixes

# version 1.0.3

* Bug fixes

# version 1.0.2

* Bug fixes

# version 1.0.1

* Bug fixes

# version 1.0

* New plot syntax, using key-value pairs for line configuration and
  Axes() for axis settings.
* Parse key-value pairs to extend/simplify gnuplot's syntax
* Use palettes from colorschemes
* Generate linetypes from colorschemes
* Gaston now does not validate that commands/data sent to gnuplot is valid.
  This opens the door to a much simplified and more flexible design.
* Extended support for multiplot.
* Bug fixes
* Debug mode
* New plot styles
* Support for more terminals

# version 0.10

* Bug fixes
* Introduce precompilation
* Refactor exceptions to use correct types
* Improve terminal configuration
* Extended support for gnuplot terminals
* More plot styles

# version 0.9

* Bug fixes
* Add ranges to imagesc
* Default to svg in notebooks


# version 0.7.4

* Add support for `dumb` text terminal
* Add a `null` terminal that does not display anything
* Tests for 0.7 pass

# version 0.7.3

* fix default size for pdf-like terminals.

# version 0.7.2

* add `linestyle` option (corresponds to gnuplot's `dashtype`)
* update docs
* fix indexing bug in image plotting

# version 0.7.1

* add `palette` option
* Use empty string as defaults for axis labels and title
* Add missing `plot!()` commands
* Update .travis.yml
* Fix tempdir problem in Windows
* Update changelog

# version 0.7

* Require Julia 0.6
* New tutorial
* New syntax for plotting
* New `set` command to set defaults
* Add support for plotting complex vectors
* Improve and add tests
* Many internal fixes and code optimization

# version 0.6

* Add support for grids
* Fix deprecations
* Restore histogram functionality broken by Julia update
* Remove support for Julia 0.3

# version 0.5.7

* Update tests to use Julia's infrastructure

# version 0.5.6

* Require Julia 0.5.

# version 0.5.5

* Update syntax again. Convert into a Julia package.

# version 0.5.4

* Update syntax to keep up with Julia.

# version 0.5.3:

User visible:

* New terminals: aqua (OS X only) and EPS.
* Improved documentation.
* Compatibility with latest Julia syntax changes.

Under the hood:

* A few bug fixes and performance improvements.

# version 0.5:

User visible:

* New high-level command imagesc.
* New high-level command surf.
* Support for printing to file; SVG, PNG, GIF and PDF formats supported.
* Add support for 'dots' plotstyle.
* Add a test framework and 93 tests.
* Remove artificial restrictions on mixing many images and curves on the
  same figure.
* Images support explicit x, y coordinates.
* Updated and improved documentation.

Under the hood:

* A few small bug fixes.
* Code has been simplified in many places.

# version 0.4:

User visible:

* Add support for x11 terminal
* Add support for printing to files (gif and svg)
* Add support for setting default values for all plot properties
* Improved documentation

Under the hood:

* Improved detection of invalid configurations
* No longer require 'figs' global variable
* Add new 'config' type to store configuration: this will allow the user
  to configure many aspects of Gaston's behavior
* File organization has been completely revamped

# version 0.3:

* Add 'high-level' plot() and histogram() functions
* Add error checking of arguments and types, to minimise risk of gnuplot
	barfing on us on misconfigured plots
* Change type names to conform to Julia conventions (no underscores)
* Improved PDF documentation
* Fixed a few bugs

# version 0.2:

* Add support for histograms, via the "boxes" plot style.
* Add example histogram to demos.
* Add support for rgbimage plot style
* Add rgbimage example to demos.
* Fix bug (issue #1 on bitbucket) in the way figure handles were used.
