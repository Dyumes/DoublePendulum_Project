#Gaëtan Veuillet
#Double pendulum - Computer Physics 1 
#2025
#Description : This code simulates a double pendulum. To find the equations, I only used
#Newtonian mechanics. Then I tranfsormed the cartesian coordinates into polar coordinates.

include("accelerations.jl")

function doublePendulumSim(m1, m2, l1, l2, tmax, θ1, θ2, w1, w2)

    #----PARAMETERS INITIALISATIONS
    #masses
    m1 = m1 #0.5#[kg]
    m2 = m2

    #rode
    l1 = l1#0.04 #[m]
    l2 = l2#0.03

    #positions
    x1s = []
    y1s = []
    x2s = []
    y2s = []

    #constants
    g = 9.81

    #----TIME PARAMETERS
    dt = 0.01
    t = 0.0
    tmax = tmax
    ts = []

    #----INITIAL CONDITIONS
    θ1 = θ1#pi + 0.0204516 # #angle of the first pendulum
    θ2 = θ2#pi + 0.0934567##angle of the second pendulum

    w1 = w1 #angular velocity of the first pendulum = dθ1/dt
    w2 = w2 #angular velocity of the second pendulum = dθ2/dt
    #a1 = 0.0 #angular acceleration of the first pendulum = d^2θ1/dt^2
    #a2 = 0.0 #angular acceleration of the second pendulum = d^2θ2/dt^2

    θ1s = []
    θ2s = []

    w1s = []
    w2s = []

    while t < tmax
        accel = accelerations(θ1, w1, θ2, w2, m1, m2, l1, l2, g)
        a1 = accel[1]
        a2 = accel[2]

        w1 += a1*dt
        w2 += a2*dt
        w1 = clamp(w1, -50.0, 50.0)
        w2 = clamp(w2, -50.0, 50.0)

        θ1 += w1*dt
        θ2 += w2*dt

        #normalization angles
        θ1 = mod(θ1 + π, 2π) - π
        θ2 = mod(θ2 + π, 2π) - π

        #cartesian coordinates recosntruction
        x1 = l1*sin(θ1)
        y1 = -l1*cos(θ1)

        x2 = x1 + l2*sin(θ2)
        y2 = y1 - l2*cos(θ2)


        #sotkcage 
        push!(ts, t)
        push!(x1s, x1)
        push!(y1s, y1)
        push!(x2s, x2)
        push!(y2s, y2)

        push!(θ1s, θ1)
        push!(θ2s, θ2)

        push!(w1s, w1)
        push!(w2s, w2)

        t+= dt
    end

    #print(length(ts))

    return ts, θ1s, θ2s, x1s, y1s, x2s, y2s, w1s, w2s


end



