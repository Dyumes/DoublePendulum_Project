#Gaëtan Veuillet
#Double pendulum - Computer Physics 1
#2025
#Description : Fuunction to compute angular accelerations.

function accelerations(θ1, w1, θ2, w2, m1, m2, l1, l2, g)
    # Calculate angular accelerations a1 and a2 for the double pendulum
    delta = θ1 - θ2

    #denomintors
    den = 2*m1 + m2 - m2*cos(2*(θ1 - θ2))

    if abs(den) < 1e-8
        return 0.0, 0.0
    end

    #TODO : CHECK/RECALCULATE AGAIN THIS ABOMINATION
    a1 = (-g*(2*m1 + m2)*sin(θ1) - m2*g*sin(θ1-2*θ2) - 2*sin(delta)*m2*(w2^2*l2 + w1^2*l1*cos(delta))) / (l1*den)
    a2 = (2*sin(delta)*(w1^2*l1*(m1+m2)+g*(m1+m2)*cos(θ1)+w2^2*l2*m2*cos(delta)))/ (l2*den)

    return a1, a2
end