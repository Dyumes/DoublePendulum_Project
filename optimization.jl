# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Optimization function and main optimization loop.

include("animationV1.jl")
include("image_video.jl")
include("doublePendulum_v1.jl")
include("comparison_video.jl")

using JLD2
using GLMakie 


function optimize_double_pendulum(fileName, debugMode = false)
    #Use to store video data in cache, so no need to reprocess every time
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

    #Actual lengths to have a reference
    l1_real_meters = 0.09174  # [m]
    l2_real_meters = 0.063  # [m]
    pixel_to_meter = l1_real_meters / l1_pixels

    if debugMode
            println("\n" * "-"^60)
        println("DATA OF THE VIDEO:")
        println("  Frames: $nbrOfFrames")
        println("  l1 (pixels): $(round(l1_pixels, digits=2)) px")
        println("  l2 (pixels): $(round(l2_pixels, digits=2)) px")
        println("  θ1_init: $(round(θ1s_vid[1], digits=5)) rad ($(round(rad2deg(θ1s_vid[1]), digits=1))°)")
        println("  θ2_init: $(round(θ2s_vid[1], digits=5)) rad ($(round(rad2deg(θ2s_vid[1]), digits=1))°)")
        println("-"^60)

    end

    #Utils functions section
    ##Normalize angle difference to [-pi, pi], so that we don't have issues with angle wrapping
    function normalize_angle_diff(a, b)
        return mod(a - b + π, 2π) - π
    end

    #Detect oscillation period from angle data, so we can penalize period mismatches
    function detect_oscillation_period(angles, dt; threshold=0.1)
        if length(angles) < 10
            return Inf
        end
        
        # Calculate angular velocities
        velocities = [angles[i] - angles[i-1] for i in 2:length(angles)]
        
        #Search for first extremum (zero crossing with sufficient velocity)
        for i in 2:length(velocities)-1
            if velocities[i] * velocities[i+1] < 0 && abs(velocities[i]) > threshold
                return (i+1) * dt  #Time at which first extremum occurs
            end
        end
        return Inf
    end


    #Compute weighted error between simulation and video data
    #The main goal is to prioritize certain aspects of the motion (like initial angles and positions) within a certain number of frames
    #so we gain better performance in the optimization
    #TODO : MAY NEED OTHER WEIGHTS TUNING, OR ADDITIONAL TERMS
    function compute_error_weighted(θ1_sim, θ2_sim, x1_sim, y1_sim, x2_sim, y2_sim,
                                θ1_vid, θ2_vid, x1_vid, y1_vid, x2_vid, y2_vid, 
                                dt; n_frames=80)
        #Calculate n as the minimum between provided n_frames and available data length
        n = min(n_frames, length(θ1_sim), length(θ1_vid))
        
        total_error = 0.0
        weights_sum = 0.0
        
        for i in 1:n
            #Weight are higher at the beginning to focus on initial conditions, then decrease exponentially
            weight = exp(-i/25)
            
            # Angle errors
            θ1_err = normalize_angle_diff(θ1_sim[i], θ1_vid[i])
            θ2_err = normalize_angle_diff(θ2_sim[i], θ2_vid[i])
            
            # Position errors
            pos_err = sqrt((x1_sim[i]-x1_vid[i])^2 + (y1_sim[i]-y1_vid[i])^2 +
                        (x2_sim[i]-x2_vid[i])^2 + (y2_sim[i]-y2_vid[i])^2)
            
            total_error += weight * (abs(θ1_err) + abs(θ2_err) + 0.3*pos_err)
            weights_sum += weight
        end
        
        #Also a penalty for period mismatch
        period_sim_θ1 = detect_oscillation_period(θ1_sim[1:n], 0.01)
        period_vid_θ1 = detect_oscillation_period(θ1_vid[1:n], dt)
        
        period_error = 0.0
        if period_sim_θ1 < Inf && period_vid_θ1 < Inf && period_vid_θ1 > 0
            period_error = abs(period_sim_θ1 - period_vid_θ1) / period_vid_θ1
        end
        
        base_error = total_error / weights_sum
        return base_error + 0.2 * period_error
    end

    #Visualization 
    function plot_comparison_glmakie(θ1_sim, θ2_sim, θ1_vid, θ2_vid, 
                                    m1_vid_x, m1_vid_y, m2_vid_x, m2_vid_y,
                                    x1_sim, y1_sim, x2_sim, y2_sim,
                                    n_frames=100, title="Comparison")
        n = min(n_frames, length(θ1_sim), length(θ1_vid))
        
        fig = Figure(size=(1200, 800))
        
        # Angles θ1
        ax1 = Axis(fig[1, 1], title="Angle θ1", xlabel="Frame", ylabel="Degree")
        lines!(ax1, 1:n, rad2deg.(θ1_sim[1:n]), label="Simulation", linewidth=3, color=:blue)
        lines!(ax1, 1:n, rad2deg.(θ1_vid[1:n]), label="Video", linewidth=2, color=:red, linestyle=:dash)
        axislegend(ax1)
        
        # Angles θ2
        ax2 = Axis(fig[1, 2], title="Angle θ2", xlabel="Frame", ylabel="Degree")
        lines!(ax2, 1:n, rad2deg.(θ2_sim[1:n]), label="Simulation", linewidth=3, color=:green)
        lines!(ax2, 1:n, rad2deg.(θ2_vid[1:n]), label="Video", linewidth=2, color=:orange, linestyle=:dash)
        axislegend(ax2)
        


        # Positions m1
        ax3 = Axis(fig[2, 1], title="Position mass 1", xlabel="x (m)", ylabel="y (m)")
        scatter!(ax3, m1_vid_x[1:n], -m1_vid_y[1:n], label="Video", color=:red, markersize=8)
        lines!(ax3, x1_sim[1:n], y1_sim[1:n], label="Simulation", linewidth=2, color=:blue)
        axislegend(ax3)
        
        # Positions m2
        ax4 = Axis(fig[2, 2], title="Position mass 2", xlabel="x (m)", ylabel="y (m)")
        scatter!(ax4, m2_vid_x[1:n], -m2_vid_y[1:n], label="Video", color=:orange, markersize=8)
        lines!(ax4, x2_sim[1:n], y2_sim[1:n], label="Simulation", linewidth=2, color=:green)
        axislegend(ax4)
        
        Label(fig[0, :], title, fontsize=20)
        
        return fig
    end

    #The optimisation is in 2 phases : 
    #1) first a broad search over masses, initial velocities and lengths so we get a rough idea of the parameters
    #2) then a refined search around the best parameters found
    #I firstly manually search for reasonable ranges for massee, lengths, angular velocities based on the video data and physical intuition
    println("\n" * "-"^60)
    println("BEGIN OPTIMISATION PROCESS")
    println("-"^60)

    # Angles are fixed relatively to video initial angles
    #TODO : MAY BE CHANGED TO FREE PARAMETERS
    θ1_fixed = θ1s_vid[1]
    θ2_fixed = θ1s_vid[1] + (θ2s_vid[1] - θ1s_vid[1])  #Preserve relative angle difference from video, so we don't have to optimize both independently

    l1_fixed = l1_real_meters
    l2_fixed = l2_real_meters


    tmax = nbrOfFrames / 100.0
    dt_vid = 1/100.0

    #Convert video positions to meters
    m1_vid_x = [(pos[1] - center[1]) * pixel_to_meter for pos in m1_Vidpos]
    m1_vid_y = [-(pos[2] - center[2]) * pixel_to_meter for pos in m1_Vidpos]
    m2_vid_x = [(pos[1] - center[1]) * pixel_to_meter for pos in m2_Vidpos]
    m2_vid_y = [-(pos[2] - center[2]) * pixel_to_meter for pos in m2_Vidpos]

    #Optimization phase function
    #The main goal here is to loop over all combinations of parameters, run the simulation, compute the error, and keep track of the best parameters found
    function run_optimization_phase(m1_range, m2_range, l1_range, l2_range, w1_range, w2_range,phase_name, n_frames_error=80)
        
        println("\n=== $phase_name ===")
        println("Combinaisons: $(length(m1_range))×$(length(m2_range))×$(length(l1_range))×" *
                "$(length(l2_range))×$(length(w1_range))×$(length(w2_range))")
        
        best_error = Inf
        best_params = Dict()
        iteration = 0
        total_combinations = length(m1_range) * length(m2_range) * length(l1_range) * 
                            length(l2_range) * length(w1_range) * length(w2_range)
        
        start_time = time()
        
        for m1 in m1_range
            for m2 in m2_range
                for l1_opt in l1_range
                    for l2_opt in l2_range
                        for w1 in w1_range
                            for w2 in w2_range
                                iteration += 1
                                
                                l1_opt = l1_fixed
                                #l2_opt = l2_fixed


                                # Simulation itself
                                ts, θ1s_sim, θ2s_sim, x1s, y1s, x2s, y2s = doublePendulumSim(
                                    m1, m2, l1_opt, l2_opt, tmax, 
                                    θ1_fixed, θ2_fixed, w1, w2
                                )
                                
                                #Calculation of error
                                error = compute_error_weighted(
                                    θ1s_sim, θ2s_sim, x1s, y1s, x2s, y2s,
                                    θ1s_vid, θ2s_vid, m1_vid_x, m1_vid_y, m2_vid_x, m2_vid_y,
                                    dt_vid, n_frames=n_frames_error
                                )
                                
                                # Check for best error -> minimizing
                                if error < best_error
                                    best_error = error
                                    best_params = Dict(
                                        "m1" => m1,
                                        "m2" => m2,
                                        "l1" => l1_opt,
                                        "l2" => l2_opt,
                                        "w1" => w1,
                                        "w2" => w2,
                                        "θ1" => θ1_fixed,
                                        "θ2" => θ2_fixed
                                    )

                                    if debugMode
                                        println("  [$(round(time()-start_time, digits=1))s] $phase_name - Error: $(round(error, digits=6))")
                                        println("    m1=$(round(m1*1000, digits=2))g, m2=$(round(m2*1000, digits=2))g, " *
                                        "l1=$(round(l1_opt*1000, digits=1))mm, l2=$(round(l2_opt*1000, digits=1))mm")
                                        println("    w1=$(round(w1, digits=3))rad/s, w2=$(round(w2, digits=3))rad/s")
                                    end
                                    
                                end
                                
                                # Progression display
                                #if debugMode
                                    if iteration % 500 == 0
                                        progress = iteration / total_combinations * 100
                                        elapsed = time() - start_time
                                        eta = elapsed / iteration * (total_combinations - iteration)
                                        #println("  [$iteration/$total_combinations] $(round(progress, digits=1))% - " * "Elapsed: $(round(elapsed, digits=1))s, ETA: $(round(eta, digits=1))s")
                                    end
                                #end
                                
                            end
                        end
                    end
                end
            end
        end
        
        elapsed_time = time() - start_time
        
        println("\n $phase_name ENDED IN $(round(elapsed_time, digits=1))s")
        println("  Best error found: $(round(best_error, digits=6))")
        println("  m1=$(round(best_params["m1"]*1000, digits=2))g, m2=$(round(best_params["m2"]*1000, digits=2))g")
        
        return best_error, best_params
    end

    #ACTUAL FIRST OPTIMIZATION PHASE
    println("\n" * "-"^60)
    println("PHASE 1: LARGE SEARCH - MASSES, LENGTHS, ANGULAR VELOCITIES")
    println("-"^60)

    #RANGE TO SEARCH OVER
    ##MASSES
    m1_range_phase1 = range(0.025, 0.035, length=5)      #Found around 30g, so search between 25g and 35g
    m2_range_phase1 = range(0.0015, 0.0030, length=5)    #Found around 2g, so search between 1.5g and 3g
    ##LENGTHS
    l1_range_phase1 = range(l1_real_meters*0.95, l1_real_meters*1.05, length = 5)                   
    l2_range_phase1 = range(l2_real_meters*0.95, l2_real_meters*1.05, length = 5)                   
    #ANGULAR VELOCITIES
    w1_range_phase1 = range(-0.5, 1, length=5)         
    w2_range_phase1 = range(-0.5, 2, length=5)
    

    best_error_phase1, best_params_phase1 = run_optimization_phase(
        m1_range_phase1, m2_range_phase1, l1_range_phase1, l2_range_phase1,
        w1_range_phase1, w2_range_phase1,
        "PHASE 1", 60  #First phase is at 60 frames for error computation, to be faster and coarser
    )

    
    

    #ONLY FOR DEBUGGING : VISUALISATION OF PHASE 1 RESULTS
    if debugMode
        newθ1s_final = []
        newθ2s_final = []
        for i in 1:length(θ1s_final)
            push!(newθ1s_final, mod(θ1s_final[i] + π, 2π))
            push!(newθ2s_final, mod(θ2s_final[i] + π, 2π))
        end

        newθ1s_vid = []
        newθ2s_vid = []
        for i in 1:length(θ1s_vid)
            push!(newθ1s_vid, mod(θ1s_vid[i] + π, 2π))
            push!(newθ2s_vid, mod(θ2s_vid[i] + π, 2π))
        end
        θ1s_final = newθ1s_final
        θ2s_final = newθ2s_final
        θ1s_vid = newθ1s_vid
        θ2s_vid = newθ2s_vid
        println("\nVisuaisation of phase 1...")
        ts_test, θ1s_test, θ2s_test, x1s_test, y1s_test, x2s_test, y2s_test = doublePendulumSim(
            best_params_phase1["m1"], best_params_phase1["m2"],
            best_params_phase1["l1"], best_params_phase1["l2"],
            tmax,
            best_params_phase1["θ1"], best_params_phase1["θ2"],
            best_params_phase1["w1"], best_params_phase1["w2"]
        )

        fig_phase1 = plot_comparison_glmakie(
            θ1s_test, θ2s_test, θ1s_vid, θ2s_vid,
            m1_vid_x, m1_vid_y, m2_vid_x, m2_vid_y,
            x1s_test, y1s_test, x2s_test, y2s_test,
            200, "Result of phase 1 - Large Search"
        )

        save("analysis/comparison_phase1.png", fig_phase1)
        println("Visualisation saved as: comparison_phase1.png")
    end
    

    

    #ACTUAL SECOND OPTIMIZATION PHASE
    println("\n" * "-"^60)
    println("PHASE 2 : REFINED SEARCH AROUND BEST PARAMETERS PHASE 1")
    println("-"^60)

    #Range narrowing around best parameters found in phase 1
    m1_center = best_params_phase1["m1"]
    m2_center = best_params_phase1["m2"]
    l1_center = best_params_phase1["l1"]
    l2_center = best_params_phase1["l2"]
    w1_center = best_params_phase1["w1"]
    w2_center = best_params_phase1["w2"]

    m1_range_phase2 = range(m1_center*0.95, m1_center*1.05, length=5)
    m2_range_phase2 = range(m2_center*0.95, m2_center*1.05, length=5)
    l1_range_phase2 = range(l1_center*0.98, l1_center*1.02, length=5)  
    l2_range_phase2 = range(l2_center*0.98, l2_center*1.02, length=5)  
    w1_range_phase2 = range(w1_center - 0.1, w1_center + 0.1, length=5)
    w2_range_phase2 = range(w2_center - 0.1, w2_center + 0.1, length=5)

    best_error_phase2, best_params_phase2 = run_optimization_phase(
        m1_range_phase2, m2_range_phase2, l1_range_phase2, l2_range_phase2,
        w1_range_phase2, w2_range_phase2,
        "PHASE 2", 80  #Same as phase 1 but slightly more frames for error computation
    )

    #FINAL RESULTS DISPLAY
    println("\n" * "-"^60)
    println("FINAL RESULTS OF THE OPTIMISATION")
    println("-"^60)

    best_params = best_params_phase2
    best_error = best_error_phase2

    println("\nBEST FOUND PAREMETERS:")
    println("  Mass 1: $(round(best_params["m1"]*1000, digits=2)) g")
    println("  Mass 2: $(round(best_params["m2"]*1000, digits=2)) g")
    println("  Length 1: $(round(best_params["l1"]*1000, digits=1)) mm")
    println("  Length 2: $(round(best_params["l2"]*1000, digits=1)) mm")
    println("  θ1 initial: $(round(best_params["θ1"], digits=5)) rad ($(round(rad2deg(best_params["θ1"]), digits=2))°)")
    println("  θ2 initial: $(round(best_params["θ2"], digits=5)) rad ($(round(rad2deg(best_params["θ2"]), digits=2))°)")
    println("  ω1 initial: $(round(best_params["w1"], digits=5)) rad/s")
    println("  ω2 initial: $(round(best_params["w2"], digits=5)) rad/s")
    println("  Final error: $(round(best_error, digits=6))")

    #Final simulation with best parameters
    println("\n" * "-"^60)
    println("FINAL SIMULATION WITH BEST PARAMETERS")
    println("-"^60)

    ts_final, θ1s_final, θ2s_final, x1s_final, y1s_final, x2s_final, y2s_final, w1s_final, w2s_final = doublePendulumSim(
        best_params["m1"], best_params["m2"],
        best_params["l1"], best_params["l2"],
        tmax,
        best_params["θ1"], best_params["θ2"],
        best_params["w1"], best_params["w2"]
    )

    newθ1s_final = []
    newθ2s_final = []
    for i in 1:length(θ1s_final)
        push!(newθ1s_final, mod(θ1s_final[i], 2π))
        push!(newθ2s_final, mod(θ2s_final[i], 2π))
    end

    newθ1s_vid = []
    newθ2s_vid = []
    for i in 1:length(θ1s_vid)
        push!(newθ1s_vid, mod(θ1s_vid[i], 2π))
        push!(newθ2s_vid, mod(θ2s_vid[i], 2π))
    end
    θ1s_final = newθ1s_final
    θ2s_final = newθ2s_final
    θ1s_vid = newθ1s_vid
    θ2s_vid = newθ2s_vid

    #Final Visualization
    println("\nVisualization of final...")
    fig_final = plot_comparison_glmakie(
        θ1s_final, θ2s_final, θ1s_vid, θ2s_vid,
        m1_vid_x, m1_vid_y, m2_vid_x, m2_vid_y,
        x1s_final, y1s_final, x2s_final, y2s_final,
        200, "Final results - end of optimisation"
    )

    save("analysis/comparison_final.png", fig_final)
    println("Saved visualisation: comparison_final.png")

    #Final Animation with best parameters
    println("\nGENERATING FINAL ANIMATION WITH BEST PARAMETERS...")
    animation_double_pendulum(
        best_params["m1"], best_params["m2"],
        best_params["l1"], best_params["l2"],
        30, 1, tmax,
        best_params["θ1"], best_params["θ2"],
        best_params["w1"], best_params["w2"],
        fileName,
        true
    )

    println("\nSaved animation as 'pendulumV1.mp4'")

    #Some stats
    println("\n" * "-"^60)
    println("STATS")
    println("-"^60)

    n_compare = min(100, length(θ1s_final), length(θ1s_vid))

    #Errors calculation
    θ1_errors = [normalize_angle_diff(θ1s_final[i], θ1s_vid[i]) for i in 1:n_compare]
    θ2_errors = [normalize_angle_diff(θ2s_final[i], θ2s_vid[i]) for i in 1:n_compare]

    rmse_θ1 = sqrt(sum(θ1_errors.^2) / n_compare)
    rmse_θ2 = sqrt(sum(θ2_errors.^2) / n_compare)
    max_θ1_err = maximum(abs.(θ1_errors))
    max_θ2_err = maximum(abs.(θ2_errors))

    println("\nError on the 100 first frames:")
    println("  θ1 - RMSE: $(round(rad2deg(rmse_θ1), digits=2))°, Max: $(round(rad2deg(max_θ1_err), digits=2))°")
    println("  θ2 - RMSE: $(round(rad2deg(rmse_θ2), digits=2))°, Max: $(round(rad2deg(max_θ2_err), digits=2))°")

    # Analyse de la période
    period_sim = detect_oscillation_period(θ1s_final[1:n_compare], 0.01)
    period_vid = detect_oscillation_period(θ1s_vid[1:n_compare], dt_vid)

    println("\nPeriod analysis:")
    if period_sim < Inf && period_vid < Inf
        println("  Simulation's period: $(round(period_sim, digits=3)) s")
        println("  Video period: $(round(period_vid, digits=3)) s")
        println("  Difference: $(round(abs(period_sim-period_vid), digits=3)) s ($(round(abs(period_sim-period_vid)/period_vid*100, digits=1))%)")
    else
        println("  NOT DETECTED IN THE  $n_compare FIRSTS FRAMES")
    end

    # Énergie
    g = 9.81
    E_initial = -(best_params["m1"] + best_params["m2"]) * g * best_params["l1"] * cos(best_params["θ1"]) - 
                best_params["m2"] * g * best_params["l2"] * cos(best_params["θ2"])
    println("\nInitiale potentiale energy: $(round(E_initial, digits=5)) J")

    println("\nOPTIMISATION PROCESS COMPLETE")

    println("\nGENERATING COMPARISON VIDEO...")

    
    create_comparison_video(
        best_params, 
        cache_file, 
        "comparison_tracking_vs_simulation.mp4", 
        30, 
        nbrOfFrames, debugMode
    )
    
    if debugMode
        println("\nAll visualizations and animations have been created")
        println("  - comparison_phase1.png")
        println("  - comparison_final.png")
        println("  - pendulumV1.mp4")
        println("  - comparison_tracking_vs_simulation.mp4")    end
    return best_params["m1"], best_params["m2"], x1s_final, y1s_final, x2s_final, y2s_final, w1s_final, w2s_final, θ1s_final, θ2s_final
end

