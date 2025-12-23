# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Main file to run the double pendulum animation and video detection.

include("animationV1.jl")
include("image_video.jl")

#masses
m1 = 0.3 #0.5#[kg]
m2 = 0.02

#rode (irl lengths)
l1 = 0.09174#0.09174#0.04 #[m]
l2 = 0.06933#0.06933#0.03

#angle
θ1 = pi+0.1#pi + 0.0204516 # #angle of the first pendulum
θ2 = pi+0.2#pi + 0.0934567##angle of the second pendulum

#animate the double pendulum
infoAnimation = animation_double_pendulum(m1, m2, l1, l2, 30, 1, 2, θ1, θ2)
θ1s_anim = infoAnimation[1]
θ2s_anim = infoAnimation[2]

#print("teta 1 : $(length(θ1s)) elements")

video = "First_Video_2s.mp4"
nbrOfFrames = 200
m1_Vidpos, m2_Vidpos, center, l1, l2, θ1s_vid, θ2s_vid= video_analysis_and_animation(video, nbrOfFrames)

#Tentative comparison between video angles and animation angles
#=
for i in 1:length(θ1s_vid)
    diff_θ1 = (θ1s_anim[i]/θ1s_vid[i]) * 100 - 100
    diff_θ2 = (θ2s_anim[i]/θ2s_vid[i]) * 100 - 100

    println("Frame $i : θ1_vid = $(θ1s_vid[i]), θ1_anim = $(θ1s_anim[i]), diff = $(θ1s_anim[i] - θ1s_vid[i]) | θ2_vid = $(θ2s_vid[i]), θ2_anim = $(θ2s_anim[i]), diff = $(θ2s_anim[i] - θ2s_vid[i])")
    println("Percentage difference : θ1 = $diff_θ1 % | θ2 = $diff_θ2 %")
    if abs(diff_θ1) > 5.0
        println("Warning: Large difference in θ1 at frame $i")
    end
    if abs(diff_θ2) > 5.0
        println("Warning: Large difference in θ2 at frame $i")
    end
end

function root_mean_squared_error(a, b)
    n = length(a)
    mse = sum((a[i] - b[i])^2 for i in 1:n) / n
    return sqrt(mse)
end

rmse_θ1 = root_mean_squared_error(θ1s_vid, θ1s_anim)
rmse_θ2 = root_mean_squared_error(θ2s_vid, θ2s_anim)

println("Root mean Squared Error for θ1: $rmse_θ1")
println("Root mean Squared Error for θ2: $rmse_θ2")

=#

rapport_rode = l2 / l1

