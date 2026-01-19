#Veuillet Gaëtan
#Double pendulum - Computer Physics 1
#2025
#Description : faster way to animate the double pendulum using GLMakie.

#TODO : REMOVE DEBUG PRINTS
using GLMakie

include("doublePendulum_v1.jl")

println("Simulation...")

function animation_double_pendulum(m1, m2, l1, l2, fps, frame_step, tmax, θ1, θ2, w1, w2, fileName, debugMode=false)
    # masses
    m1_val = m1
    m2_val = m2

    # rodes
    l1_val = l1
    l2_val = l2

    θ1_val = θ1
    θ2_val = θ2

    ts, θ1s, θ2s, x1s, y1s, x2s, y2s, w1s, w2s = doublePendulumSim(m1_val, m2_val, l1_val, l2_val, tmax, θ1_val, θ2_val, w1, w2)

    # Frames parameters
    fps_val = fps
    frame_step_val = frame_step

    indices = 1:frame_step_val:length(ts)

    # ONLY FOR DEBUG
    println("Nbr of frames: $(length(indices))")

    # Calculate limits
    all_x = vcat(x1s, x2s)
    all_y = vcat(y1s, y2s)
    max_len = l1_val + l2_val # lengths rode
    L = 1.1 * max_len

    # Create the figure and axis
    fig = Figure(size=(800, 800))
    ax = Axis(fig[1, 1], 
            limits=(-L, L, -L, L),
            aspect=1,
            yreversed=false, # depend
            title="Double Pendulum",
            xlabel="x",
            ylabel="y")

    # Simulation information text
    info_text = """
    Simulation Parameters:
    • Mass 1 (m1): $(round(m1_val, digits=4)) kg
    • Mass 2 (m2): $(round(m2_val, digits=4)) kg
    • Rod 1 length: $(round(l1_val, digits=3)) m
    • Rod 2 length: $(round(l2_val, digits=3)) m
    • Initial θ1: $(round(θ1_val, digits=3)) rad
    • Initial θ2: $(round(θ2_val, digits=3)) rad
    • Total time: $(tmax) s
    • FPS: $fps_val
    """

    # Add text box to display simulation info
    if debugMode == true
        text!(ax, -L + 0.05, L - 0.05, 
          text=info_text,
          align=(:left, :top),
          color=:black,
          fontsize=12,
          space=:data,
          font="DejaVu Sans Mono")
    end
    
    # First rode
    line1_x = Observable([0.0, 0.0])
    line1_y = Observable([0.0, 0.0])

    # Second rode
    line2_x = Observable([0.0, 0.0])
    line2_y = Observable([0.0, 0.0])

    # Create the rodes
    lines!(ax, line1_x, line1_y, color=:blue, linewidth=3)
    lines!(ax, line2_x, line2_y, color=:red, linewidth=3)

    # Initialize the points
    point1 = Observable(Point2f(0, 0))
    point2 = Observable(Point2f(0, 0))

    # Add the points to the axis
    scatter!(ax, point1, color=:blue, markersize=15)
    scatter!(ax, point2, color=:red, markersize=15)

    # Add labels for the masses
    if debugMode == true
      text!(ax, 0.1, 0.1, text="m1 = $(round(m1_val, digits=3)) kg", 
          align=(:left, :bottom), color=:blue, fontsize=10)
      text!(ax, 0.1, 0.05, text="m2 = $(round(m2_val, digits=3)) kg", 
          align=(:left, :bottom), color=:red, fontsize=10)
    end


    # The way GLMakie updates frames
    function update_frame(i)
        j = indices[i]
        
        # update rode1
        line1_x[] = [0.0, x1s[j]]
        line1_y[] = [0.0, y1s[j]]
        
        # update rode2
        line2_x[] = [x1s[j], x2s[j]]
        line2_y[] = [y1s[j], y2s[j]]
        
        # update the points
        point1[] = Point2f(x1s[j], y1s[j])
        point2[] = Point2f(x2s[j], y2s[j])
        
        # update the time into the title
        ax.title[] = "Double Pendulum - t = $(round(ts[j], digits=2)) s"
        
    end

    println("\nRegister the animation...")
    @time record(fig, "videos/$(fileName)", 1:length(indices);
                framerate=fps_val) do i
        update_frame(i)
    end

    println("Animation saved")

    return -θ1s, -θ2s, x1s, y1s, x2s, y2s, w1s, w2s
end