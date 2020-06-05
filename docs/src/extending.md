# Extending Gaston

Gaston offers multiple plotting commands that cover most cases of general data plotting. However, it is sometimes convenient to extend its capabilities to cover more specific use cases. One simple case is the generation of consistent plots of a certain type. A more complex example is plotting of new types, not just numerical data. We illustrate these two cases with examples.

## Consistent plots in a specific application

Consider this situation: we are designing and simulating a new communications algorithms and we need to plot the resulting bit error rate (BER). BER plots have certain characteristics:

* The x label defaults to `E_b/N_0 (dB)`.
* The y label defaults to `Bit Error Rate`, but could also be `Symbol Error Rate`.
* The y axis is logarithmic, and we want the tics to be negative powers of ten.
* The grid should be visible.
* The plot title defaults to `BER as a function of SNR`.
* We wish to have markers at each SNR value, defaulting to full diamonds.
* We like to use a thick line (width 2) that defaults to color blue.

Let us define a new plot command, called `berplot`, that allows us to do this.

```@example ext
using Gaston # hide
set(reset=true) # hide
set(termopts="size 550,325 font 'Consolas,11'") # hide
function berplot(snr, ber, axes::Axes = Axes() ; ser = false, args...)

    # support an optional Boolean argument to control the y label
    ylab = "'Bit Error Rate'"
    if ser
        ylab = "'Symbol Error Rate'"
    end

    # Build the default axes configuration
    a = Axes(title  = "'BER as a function of SNR'",
             xlabel = "'E_b/N_0 (dB)'",
             ylabel = ylab,  # use the label specified by ser
             axis   = "semilogy",
             grid   = "on",
             ytics  = "out format '10^{%T}'"
            )

    # Execute the plot command with the default curve configuration. Note that
    # the default axes configuration is merged with the one provided by the
    # user, giving preference to the latter.
    plot(snr, ber, Gaston.merge(a, axes) ;
         w = :lp,
         lc = :blue,
         lw = 2,
         marker = "fdmd",
         args...
        )
end
```

Let us try it out:

```@example ext
using SpecialFunctions
Q(x) = 0.5erfc(x/sqrt(2))
snr = 3:15
snr_dB = 10log10.(snr)
ber = 4Q.(sqrt.(snr))
berplot(snr_dB, ber)
```

Let us verify that we can control the y label:

```@example ext
berplot(snr_dB, ber, ser = true)
```

And verify that we can override the defaults:

```@example ext
berplot(snr_dB, ber, Axes(grid = "xtics mytics"), lc = :orange)
```

## Plotting a new type

As an example, let us extend `plot` to display the frequency and phase response of a filter designed with [DSP.jl](https://docs.juliadsp.org/stable/filters/). The idea is to plot magnitude and phase responses in two subplots, Matlab-style.

```@example ext
using DSP, FFTW

fs = 200.
df = digitalfilter(Lowpass(50, fs=fs), Chebyshev1(21, 0.5))
typeof(df)
```

We cannot run `plot(df)` directly, since neither Gaston nor gnuplot know what to do with data of this type.. We need to extend `plot` to type `ZeroPoleGain`, wee can also define a default plot configuration.

```@example ext
# We need to explicitly import plot, since we're extending it.
import Gaston.plot

function plot(x::ZeroPoleGain, axes::Axes = Axes() ; fs = π, n = 250, args...)
    # The filter's frequency response is obtained with freqz.
    f = range(0, fs/2, length = n)
    fz = freqz(x, f, fs)
    mg = abs.(fz)
    ph = angle.(fz)

    # magnitude plot
    a = Axes(title = "'Magnitude response'",
             grid = :on,
             xlabel = "'Frequency'",
             ylabel = "'Magnitude'")
    p1 = plot(f, mg, merge(a, axes) ; handle = Gaston.nexthandle(), args...)

    # phase plot
    a = Axes(title = "'Phase response'",
             grid = :on,
             xlabel = "'Frequency'",
             ylabel = "'Phase'")
    p2 = plot(f, ph, merge(a, axes) ; handle = Gaston.nexthandle(), args...)

    plot([p1 ; p2])

end
```

Note that, when creating plots for the magnitude and phase response, the function `Gaston.nexthandle()` is used to select a new, unused handle. The reason is that `plot` overwrites the last created plot. So, when defining `p1` we run the risk of overwriting the last plot the user created, and when defining `p2` we run the risk of overwriting `p1`. These are avoided by choosing handles that are not shared with any other plots.

Let us test it:

```@example ext
set(termopts = "size 550, 600 font 'Consolas,11'")  # hide
plot(df, fs=fs)
```
