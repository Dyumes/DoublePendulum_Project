# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Main file to run the double pendulum animation and video detection.

using GLMakie

include("animationV1.jl")
include("image_video.jl")
include("optimization.jl")
include("energy.jl")

#FIRST PART IS JUST TO SIMULATE A DOUBLE PENDULUM AND ANIMATE IT
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

#SECOND PART IS TO PROCESS A VIDEO OF A DOUBLE PENDULUM AND OPTIMIZE ITS PARAMETERS TO FIT THE VIDEO
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

#THIRD PART IS TO CALCULATE THE ENERGIES OF THE DOUBLE PENDULUM SIMULATION
g = 9.81

p1s = [[x1s_final[i], y1s_final[i]] for i in 1:length(x1s_final)]
p2s = [[x2s_final[i], y2s_final[i]] for i in 1:length(x2s_final)]

energy_traj(p1s, p2s, w1s_final, w2s_final, m1_opti, m2_opti, g)
