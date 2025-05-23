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

function pushorreplace!(v, pair)
    pf = pair.first
    for i in eachindex(v)
        if v[i].first == pf
            # replace
            v[i] = pair
            return
        end
    end
    # insert
    push!(v, pair)
end

function expand(d...)
    dd = Pair[]
    for (k,v) in d
        if v isa Vector{Pair}
            for (k1,v1) in v
                push!(dd, k1 => v1)
            end
        else
            push!(dd, k => v)
        end
    end
    return dd
end

function prockey(key)
    if @capture(key, a_ = b_)
        return :($(string(a)) => $b)
    elseif @capture(key, g_...)
        return :("theme" => $g)
    elseif @capture(key, a_)
        return :($(string(a)) => true)
    end
end

function procopts(d)
    if @capture(d, {xs__})
        return :($(expand)($(map(prockey, xs)...)))
    elseif @capture(d, f_(xs__))
        return :($f($(map(procopts, xs)...)))
    else
        return d
    end
end

"""
    @gpkw

Convert a variable number of keyword arguments to a vector of pairs of strings.

# Example

```julia
julia> @gpkw {title = Q"Example", grid = true}
2-element Vector{Pair}:
 "title" => "'Example'"
  "grid" => true
```
"""
macro gpkw(ex)
    esc(postwalk(procopts, ex))
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
    args = (esc(procopts(v)) for v in ex)
    :( plot($(args...)) )
end

"""
    @plot! args...

Alternative Convenient syntax for `plot!`. See the documentation for `@plot`.
"""
macro plot!(ex...)
    args = (esc(procopts(v)) for v in ex)
    :( plot!($(args...)) )
end

"""
    @splot args...

Alternative Convenient syntax for `splot`. See the documentation for `@plot`.
"""
macro splot(ex...)
    args = (esc(procopts(v)) for v in ex)
:( splot($(args...)) )
end

"""
    @splot! args...

Alternative Convenient syntax for `splot!`. See the documentation for `@plot`.
"""
macro splot!(ex...)
    args = (esc(procopts(v)) for v in ex)
    :( splot!($(args...)) )
end
