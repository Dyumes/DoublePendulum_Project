#Veuillet Gaëtan
#Double pendulum - Computer Physics 1
#2025
#Description : faster way to animate the double pendulum using GLMakie.

#TODO : REMOVE DEBUG PRINTS
using GLMakie

include("doublePendulum_v1.jl")

println("Simulation...")

function animation_double_pendulum(m1, m2, l1, l2, fps, frame_step, tmax)
    #masses
    m1 = m1
    m2 = m2

    #rode
    l1 = l1
    l2 = l2
    ts, θ1s, θ2s, x1s, y1s, x2s, y2s = doublePendulumSim(m1, m2, l1, l2, tmax)

    #Frames parameters
    fps = fps
    frame_step = frame_step

    indices = 1:frame_step:length(ts)

    #ONLY FOR DEBUG
    println("Nbr of frames: $(length(indices))")

    #Calculate limits
    all_x = vcat(x1s, x2s)
    all_y = vcat(y1s, y2s)
    max_len = l1 + l2 #lengths rode
    L = 1.1 * max_len

    #Create the figure and axis
    fig = Figure(size=(800, 800))
    ax = Axis(fig[1, 1], 
            limits=(-L, L, -L, L),
            aspect=1,
            yreversed=false,#depend
            title="Double Pendulum",
            xlabel="x",
            ylabel="y")

    #
    #First rode
    line1_x = Observable([0.0, 0.0])
    line1_y = Observable([0.0, 0.0])

    #Second rode
    line2_x = Observable([0.0, 0.0])
    line2_y = Observable([0.0, 0.0])

    #Create the rodes
    lines!(ax, line1_x, line1_y, color=:blue, linewidth=3)
    lines!(ax, line2_x, line2_y, color=:red, linewidth=3)

    #Initialize the points
    point1 = Observable(Point2f(0, 0))
    point2 = Observable(Point2f(0, 0))

    #Add the points to the axis
    scatter!(ax, point1, color=:blue, markersize=15)
    scatter!(ax, point2, color=:red, markersize=15)

    #The way GLMakie updates frames
    function update_frame(i)
        j = indices[i]
        
        #update rode1
        line1_x[] = [0.0, x1s[j]]
        line1_y[] = [0.0, y1s[j]]
        
        # update rode2
        line2_x[] = [x1s[j], x2s[j]]
        line2_y[] = [y1s[j], y2s[j]]
        
        #update the points
        point1[] = Point2f(x1s[j], y1s[j])
        point2[] = Point2f(x2s[j], y2s[j])
        
        #update the time into the tile
        ax.title[] = "Double Pendulum - t = $(round(ts[j], digits=2)) s"
    end

    println("\nRegister the animation...")
    @time record(fig, "pendulumV1.mp4", 1:length(indices);
                framerate=fps) do i
        update_frame(i)
    end

    println("Animation saved")

end
