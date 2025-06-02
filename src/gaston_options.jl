# Macro and functions to handle options in brackets

"""
    @Q_str

Inserts single quotation marks around a string.

When passing options to gnuplot, some arguments should be quoted and some should
not. For example:

* `set title Example    # gnuplot errors`
* `set title 'Example'  # the title must be quoted`
* `set pointtype 7      # the point type is not quoted`

Gaston allows setting options using keyword arguments:

```julia
@plot {title = "Example"} x y  # converted to "set title Example"
```

Here, the keyword argument should be `{title = "'Example'"}`, which is correctly
converted to `set title 'Example'`. To avoid having to type the single quotes,
this macro allows us to write:

```julia
@plot {title = Q"Example"} x y  # converted to "set title 'Example'"
```
"""
macro Q_str(s)
    "'$s'"
end

"""
    @plot args...

@plot provides an alternative syntax for plotting. The arguments are interpreted
similarly to `plot`: first, a figure or axis may be specified; then, data is
provided, and finally a plotline may be given. This macro allows specifying
gnuplot settings as `setting = value`, which is converted to `set setting value`
before passing it to gnuplot. These key, value pairs must be surrounded by
curly brackets.

# Examples

```{.julia}
# Plot a sine wave with title `example` and with a grid, with a red line
@plot {title = "'example'", grid = true} sin {lc = 'red'}
```

In this example, `grid = true` is converted to `set grid`. To disable a
setting, use (for example) `grid = false` (converted to `unset grid`).
"""
macro plot(ex...)
    args = []
    kwargs = Pair{Symbol,Any}[]
    for el in ex
        Meta.isexpr(el, :(=)) ? push!(kwargs, Pair(el.args...)) : push!(args, el)
    end
    args2 = (esc(procopts(v)) for v in args)
    :( plot($(args2...) ; $kwargs...) )
end

"""
    @plot! args...

Alternative Convenient syntax for `plot!`. See the documentation for `@plot`.
"""
macro plot!(ex...)
    args = []
    kwargs = Pair{Symbol,Any}[]
    for el in ex
        Meta.isexpr(el, :(=)) ? push!(kwargs, Pair(el.args...)) : push!(args, el)
    end
    args2 = (esc(procopts(v)) for v in args)
    :( plot!($(args2...) ; $kwargs...) )
end

"""
    @splot args...

Alternative Convenient syntax for `splot`. See the documentation for `@plot`.
"""
macro splot(ex...)
    args = []
    kwargs = Pair{Symbol,Any}[]
    for el in ex
        Meta.isexpr(el, :(=)) ? push!(kwargs, Pair(el.args...)) : push!(args, el)
    end
    args2 = (esc(procopts(v)) for v in args)
    :( splot($(args2...) ; $kwargs...) )
end

"""
    @splot! args...

Alternative Convenient syntax for `splot!`. See the documentation for `@plot`.
"""
macro splot!(ex...)
    args = []
    kwargs = Pair{Symbol,Any}[]
    for el in ex
        Meta.isexpr(el, :(=)) ? push!(kwargs, Pair(el.args...)) : push!(args, el)
    end
    args2 = (esc(procopts(v)) for v in args)
    :( splot!($(args2...) ; $kwargs...) )
end
