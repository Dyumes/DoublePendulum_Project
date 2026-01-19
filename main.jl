# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Main file to run the double pendulum animation and video detection.

using GLMakie

include("animationV1.jl")
include("image_video.jl")
include("optimization.jl")

#masses
m1 = 0.03 #0.5#[kg]
m2 = 0.002

#rode (irl lengths)
l1 = 0.09174#0.09174#0.04 #[m]
l2 = 0.06933#0.06933#0.03

#angle
θ1 = pi+0.0204516#pi + 0.0204516 # #angle of the first pendulum
θ2 = pi+0.0934567#pi + 0.0934567##angle of the second pendulum

w1 = 0.0
w2 = 0.0

tmax = 2.0 #max time of the simulation [s]

#animate the double pendulum
fileName = "pendulumV1.mp4"
infoAnimation = animation_double_pendulum(m1, m2, l1, l2, 30, 1, 2, θ1, θ2,w1,w2,fileName,true)
θ1s_anim = infoAnimation[1]
θ2s_anim = infoAnimation[2]

#print("teta 1 : $(length(θ1s)) elements")

video = "First_Video_2s.mp4"
nbrOfFrames = 200
cache_file = "video_data_cache.jld2"

if isfile(cache_file)
    println("Loading Video's data from cache...")
    @load cache_file frames m1_Vidpos m2_Vidpos center l1 l2 θ1s_vid θ2s_vid
    l1_pixels = l1
    l2_pixels = l2
    println("Video's data LOADED")
else
    println("Processing video...")
    frames, m1_Vidpos, m2_Vidpos, center, l1_pixels, l2_pixels, θ1s_vid, θ2s_vid = video_analysis_and_animation(video, nbrOfFrames)
    l1 = l1_pixels
    l2 = l2_pixels
    println("Saving video's data to cache...")
    @save cache_file frames m1_Vidpos m2_Vidpos center l1 l2 θ1s_vid θ2s_vid
    println("Cache CREATED")
end

fileName = "pendulumOptimized.mp4"

m1_opti, m2_opti, x1s_final, y1s_final, x2s_final, y2s_final, w1s_final, w2s_final,  = optimize_double_pendulum(fileName, false)

fps = 100

dt = 1/fps  
n = 1
ω1_final = (θ1s_vid[end] - θ1s_vid[end-n]) / (dt)
ω2_final = (θ2s_vid[end] - θ2s_vid[end-n]) / (dt)
print("ω1_final : $ω1_final - ω2_final : $ω2_final \n")

l1_real_meters = 0.09174  # [m]
l2_real_meters = 0.0648  # [m]
pixel_to_meter = l1_real_meters / l1_pixels

tmax_prediction = 2.0

_,_,_,_,_,w1s, w2s = animation_double_pendulum(m1_opti, m2_opti, l1_real_meters, l2_real_meters, fps/3, n, tmax_prediction, θ1s_vid[end], θ2s_vid[end], ω1_final, ω2_final, "pendulePrediction.mp4", false)

println("W1s : $(length(w1s))")
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
    
    return kinetic_energies, potential_energies, total_energies
end

# Calculer les énergies de la simulation optimisée
g = 9.81  # accélération gravitationnelle [m/s²]

# Créer les vecteurs de positions à partir de x1s, y1s, x2s, y2s
p1s = [[x1s_final[i], y1s_final[i]] for i in 1:length(x1s_final)]
p2s = [[x2s_final[i], y2s_final[i]] for i in 1:length(x2s_final)]

# Calculer les énergies
kinetic_energies, potential_energies, total_energies = energy_traj(p1s, p2s, w1s_final, w2s_final, m1_opti, m2_opti, g)

# Créer le vecteur de temps
temps = range(0, stop=dt*(length(kinetic_energies)-1), length=length(kinetic_energies))

# Tracer les énergies avec GLMakie
fig = Figure(size=(1000, 600))
ax = Axis(fig[1, 1], 
    xlabel="Time [s]", 
    ylabel="Energy [J]",
    title="Energy of the double pendulum (optimized simulation)")

lines!(ax, temps, kinetic_energies, label="Kinetic energy", linewidth=2, color=:blue)
lines!(ax, temps, potential_energies, label="Potential energy", linewidth=2, color=:red)
lines!(ax, temps, total_energies, label="Total energy", linewidth=2, color=:green, linestyle=:dash)

axislegend(ax, position=:rt)

# Afficher la figure
display(fig)

# Sauvegarder le graphique
save("energies_optimized.png", fig)
println("Graphique des énergies sauvegardé : energies_optimized.png")

# Afficher quelques statistiques
println("\n-ENERGY STATS-")
println("Total initial energy : $(total_energies[1]) J")
println("Total final energy : $(total_energies[end]) J")
println("Variation : $((total_energies[end] - total_energies[1])/total_energies[1] * 100) %")
println("Ecart-type of total energy : $(std(total_energies)) J")