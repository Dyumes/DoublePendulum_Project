# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Main file to run the double pendulum animation. (Saved as "pendulumV1.mp4")

include("animationV1.jl")

#masses
m1 = 0.03 #0.5#[kg]
m2 = 0.002

#rode
l1 = 0.09174#0.04 #[m]
l2 = 0.06933#0.03

#animate the double pendulum
animation_double_pendulum(m1, m2, l1, l2, 60, 2, 20)