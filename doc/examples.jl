using Gaston

# plot example
t = 0:0.0001:.15
carrier = cos(2pi*t*200)
modulator = 0.7+0.5*cos(2pi*t*15)
am = carrier.*modulator
plot(t,am,"color","blue","legend","AM DSB-SC","linewidth",1.5,
    t,modulator,"color","black","legend","Envelope",
    t,-modulator,"color","black","title","AM DSB-SC example",
    "xlabel","Time (s)","ylabel","Amplitude",
    "box","horizontal top left")
set_filename("plotex.pdf")
set_print_linewidth(2)
set_print_fontsize(12)
set_print_size("6.5in,3.9in")
printfigure()

# histogram example
y = sqrt( randn(1000).^2 + randn(1000).^2 )
histogram(y,"bins",25,"norm",1,"color","blue","title",
    "Rayleigh density (25 bins)")
set_filename("histoex.pdf")
printfigure()

# imagesc example
z = zeros(10,10,3)
z[:,:,1] = 255*rand(10,10)
z[:,:,2] = 128*rand(10,10)+40
z[:,:,3] = 64*rand(10,10)+190
imagesc(z,"title","imagesc demo")
set_filename("imagescex.pdf")
printfigure()

# surf example
run(`sleep 0.5`)
gnuplot_send("set view 67,25")
surf(-3:.1:3,-3:0.1:3,(x,y)->cos(x)*sin(y),"plotstyle",
    "points","xlabel","coord 1","ylabel","coord 2","zlabel","coord 3",
    "title","surf demo","color","blue")
set_filename("surfex.pdf")
printfigure()
