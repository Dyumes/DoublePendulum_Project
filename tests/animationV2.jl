#Veuillet Gaëtan
#Double pendulum - Computer Physics 1
#2025
#escription : A try to do an interactive animation
#TODO : ERM WHAT THE SIGMA HOW THE HELL DO I MAKE THE TITLE OF THE SLIDER UPDATE WITH THE VALUE ????

using GLMakie

include("doublePendulum_v1.jl")

#Observable are used to store parameters that can be modified via widgets
m1 = Observable(1.0)
m2 = Observable(1.0)
l1 = Observable(1.0)
l2 = Observable(0.5)
θ1_init = Observable(pi + 0.1)
θ2_init = Observable(-pi - 0.1)

fig = Figure(resolution=(900, 600))

#Axis for the double pendulum
ax = Axis(fig[1,1], aspect=1, yreversed=true, title="Double Pendulum")
line1_x = Observable([0.0, 0.0])
line1_y = Observable([0.0, 0.0])
line2_x = Observable([0.0, 0.0])
line2_y = Observable([0.0, 0.0])
lines!(ax, line1_x, line1_y, color=:blue, linewidth=3)
lines!(ax, line2_x, line2_y, color=:red, linewidth=3)

# Points
point1 = Observable(Point2f(0,0))
point2 = Observable(Point2f(0,0))
scatter!(ax, point1, color=:blue, markersize=10)
scatter!(ax, point2, color=:red, markersize=10)

#Widgets for parameters
Label(fig[2,1], "Masse 1 (kg)")

slider_m1 = Slider(fig[2,1], range=0.1:0.05:2.0, startvalue=m1[])
slider_m2 = Slider(fig[3,1], range=0.1:0.05:2.0, startvalue=m2[])
slider_l1 = Slider(fig[4,1], range=0.1:0.1:2.0, startvalue=l1[])
slider_l2 = Slider(fig[5,1], range=0.1:0.1:2.0, startvalue=l2[])
slider_θ1 = Slider(fig[6,1], range=0:0.01:2pi, startvalue=θ1_init[])
slider_θ2 = Slider(fig[7,1], range=0:0.01:2pi, startvalue=θ2_init[])

button = Button(fig[8,1], label="Lancer la simulation")

#Link slider to observables
#TODO : MAY HAVE A BETTER WAY TO DO IT
on(slider_m1.value) do val m1[] = val end
on(slider_m2.value) do val m2[] = val end
on(slider_l1.value) do val l1[] = val end
on(slider_l2.value) do val l2[] = val end
on(slider_θ1.value) do val θ1_init[] = val end
on(slider_θ2.value) do val θ2_init[] = val end

#Function to run the sim
function run_simulation!()
    println("Simulation...")
    ts, θ1s, θ2s, x1s, y1s, x2s, y2s = doublePendulumSim(; 
        m1=m1[], m2=m2[], l1=l1[], l2=l2[], θ1_init=θ1_init[], θ2_init=θ2_init[]
    )
    
    #Calculate limits
    all_x = vcat(x1s, x2s)
    all_y = vcat(y1s, y2s)
    L = 1.1 * maximum([maximum(abs.(all_x)), maximum(abs.(all_y))])
    ax.limits = (-L, L, -L, L)

    fps = 60
    frame_step = 2
    indices = 1:frame_step:length(ts)

    @async record(fig, "pendulumV2.mp4", 1:length(indices); framerate=fps) do i
        j = indices[i]
        line1_x[] = [0.0, x1s[j]]
        line1_y[] = [0.0, y1s[j]]
        line2_x[] = [x1s[j], x2s[j]]
        line2_y[] = [y1s[j], y2s[j]]
        point1[] = Point2f(x1s[j], y1s[j])
        point2[] = Point2f(x2s[j], y2s[j])
        ax.title[] = "Double Pendulum - t=$(round(ts[j], digits=2))s"
    end
end

#TODO: Correct the button to run the sim
on(button.clicks) do _
    run_simulation!()
end

fig
