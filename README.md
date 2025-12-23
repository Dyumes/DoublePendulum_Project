# Context
Simulation of a double pendulum and detection of a double pendulum from a 2-second video, with the goal of predicting the continuation of this video.
Firstly, a double pendulum simulation is available under `doublePendulum_v1.jl`. It can be called from `main.jl` by setting the masses and the rod lengths.

## Double pendulum simulation
![Double Pendulum Simulation](assets/doublePendulum_sim.gif)
## Video detection
![Video double pendulum](assets/doublePendulum_video.gif)
## TODO 
1) Extract all the information from the video.
2) Find a way to minimize the error of the simulation based on the known information from the video.
3) Simulate the continuation of the video.