#Gaëtan Veuillet
#Double pendulum - Computer Physics 1 
#2025
#Description : This code simulates a double pendulum. To find the equations, I only used
#Newtonian mechanics. Then I tranfsormed the cartesian coordinates into polar coordinates.

#TODO : Not finished yet
include("accelerations.jl")

#Differences with v1 -> This simultion function takes parameters as inputs with default values -> so the animation can have a GUI to change them
function doublePendulumSim(; 
        m1=1.0, m2=1.0, 
        l1=1.0, l2=0.5, 
        θ1_init=pi + 0.1, θ2_init=-pi - 0.1,
        tmax=30.0, dt=0.01)

    #----PARAMETERS INITIALISATIONS
    #masses
    m1 = m1
    m2 = m2

    #rode
    l1 = l1 #length
    l2 = l2 #length

    #positions
    x1s = []
    y1s = []
    x2s = []
    y2s = []

    #constants
    g = 9.81

    #----TIME PARAMETERS
    dt = dt
    t = 0.0
    tmax = tmax
    ts = []

    #----INITIAL CONDITIONS
    θ1 =  θ1_init#angle of the first pendulum
    θ2 = θ2_init#angle of the second pendulum

    w1 = 0.0 #angular velocity of the first pendulum = dθ1/dt
    w2 = 0.0 #angular velocity of the second pendulum = dθ2/dt
    #a1 = 0.0 #angular acceleration of the first pendulum = d²θ1/dt²
    #a2 = 0.0 #angular acceleration of the second pendulum = d²θ2/dt²

    θ1s = []
    θ2s = []
    while t < tmax
        accel = accelerations(θ1, w1, θ2, w2, m1, m2, l1, l2, g)
        a1 = accel[1]
        a2 = accel[2]

        w1 += a1*dt
        w2 += a2*dt

        θ1 += w1*dt
        θ2 += w2*dt

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

        t+= dt
    end

    return ts, θ1s, θ2s, x1s, y1s, x2s, y2s



end



