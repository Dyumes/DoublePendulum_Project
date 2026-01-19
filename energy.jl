function kinEn(m1, m2, w1, w2, pos1, pos2)
    v1x = -w1 * pos1[2]
    v1y = w1 * pos1[1]
    v1_squared = v1x^2 + v1y^2

    rx = pos2[1] - pos1[1]
    ry = pos2[2] - pos1[2]

    v2x = v1x - w2 * ry
    v2y = v1y + w2 * rx
    v2_squared = v2x^2 + v2y^2

    return 0.5 * m1 * v1_squared + 0.5 * m2 * v2_squared
end

function potEn(m1, m2, pos1, pos2, g)
    potential_energy = m1 * g * pos1[2] + m2 * g * pos2[2]
    return potential_energy
end

function totalEn(m1, m2, w1, w2, pos1, pos2, g)
    return kinEn(m1, m2, w1, w2, pos1, pos2) + potEn(m1, m2, pos1, pos2, g)
end

function energy_traj(p1s, p2s, w1s, w2s, m1, m2, g)
    kinetic_energies = []
    potential_energies = []
    total_energies = []

    for i in 1:length(p1s)
        ke = kinEn(m1, m2, w1s[i], w2s[i], p1s[i], p2s[i])
        pe = potEn(m1, m2, p1s[i], p2s[i], g)
        te = ke + pe

        push!(kinetic_energies, ke)
        push!(potential_energies, pe)
        push!(total_energies, te)
    end
    
    #Create time array
    temps = range(0, stop=dt*(length(kinetic_energies)-1), length=length(kinetic_energies))

    fig = Figure(size=(1000, 600))
    ax = Axis(fig[1, 1], 
        xlabel="Time [s]", 
        ylabel="Energy [J]",
        title="Energy of the double pendulum (optimized simulation)")

    lines!(ax, temps, kinetic_energies, label="Kinetic energy", linewidth=2, color=:blue)
    lines!(ax, temps, potential_energies, label="Potential energy", linewidth=2, color=:red)
    lines!(ax, temps, total_energies, label="Total energy", linewidth=2, color=:green, linestyle=:dash)

    axislegend(ax, position=:rt)

    #display(fig)

    save("energies_optimized.png", fig)
    println("Energy gfaph saved: energies_optimized.png")

    println("\n-ENERGY STATS-")
    println("Total initial energy : $(total_energies[1]) J")
    println("Total final energy : $(total_energies[end]) J")
    println("Variation : $((total_energies[end] - total_energies[1])/total_energies[1] * 100) %")
    println("Ecart-type of total energy : $(std(total_energies)) J")

    #return kinetic_energies, potential_energies, total_energies
end


