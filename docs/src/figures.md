# Managing multiple figures

When using a graphical terminal such as `qt` or `wxt`, it is possible to have multiple figures on the screen at one time. Gaston provides a few commands to help manage them.

Each figure is identified by its handle, which must be an integer larger than zero. Handles don't have to be consecutive. Plotting commands accept an optional handle argument, which directs the plot to the specified figure. For example, in this code:

```julia
t = -5:0.01:5
plot(t, sin)
figure()  # creates a new figure
plot(t, cos)
plot!(t, sin.(t).^2, handle = 1)
```
the cosine will be plotted in a second figure, while the squared sine will be appended to the first figure.

```@docs
figure
closefigure
closeall
```
