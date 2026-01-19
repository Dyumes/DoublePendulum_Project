# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Create a side-by-side comparison video between tracked video and optimized simulation

using GLMakie
using JLD2

include("doublePendulum_v1.jl")

function create_comparison_video(best_params, video_cache_file="video_data_cache.jld2", output_file="comparison_tracking_vs_simulation.mp4", fps=30, nbrOfFrames=200, debugMode=false)
    
    println("\n" * "-"^60)
    println("CREATING COMPARISON VIDEO")
    println("-"^60)
    
    # Load video data from cache
    if !isfile(video_cache_file)
        error("Cache file not found: Please run the video analysis first.")
    end
    
    println("\nLoading video data from cache...")
    @load video_cache_file frames m1_Vidpos m2_Vidpos center l1 l2 θ1s_vid θ2s_vid
    l1_pixels = l1
    l2_pixels = l2
    println("Video data loaded successfully")
    
    # Real measurements for conversion
    l1_real_meters = 0.09174  # [m]
    l2_real_meters = 0.06933  # [m]
    pixel_to_meter = l1_real_meters / l1_pixels
    
    # Convert video positions to meters (relative to center)
    # Try inverting Y to match simulation orientation
    m1_vid_x = [(pos[1] - center[1]) * pixel_to_meter for pos in m1_Vidpos]
    m1_vid_y = [-(pos[2] - center[2]) * pixel_to_meter for pos in m1_Vidpos]  # Inverted
    m2_vid_x = [(pos[1] - center[1]) * pixel_to_meter for pos in m2_Vidpos]
    m2_vid_y = [-(pos[2] - center[2]) * pixel_to_meter for pos in m2_Vidpos]  # Inverted
    
    if debugMode
        println("\nDEBUG - First 5 positions:")
        println("Video m1: x=$(m1_vid_x[1:5]), y=$(m1_vid_y[1:5])")
        println("Video m2: x=$(m2_vid_x[1:5]), y=$(m2_vid_y[1:5])")
    end
    
    
    # Run simulation with best parameters
    println("\nRunning simulation with optimized parameters...")
    tmax = nbrOfFrames / fps
    dt_sim = 0.01  # Define here so it's available throughout the function
    
    ts_sim, θ1s_sim, θ2s_sim, x1s_sim, y1s_sim, x2s_sim, y2s_sim = doublePendulumSim(
        best_params["m1"], best_params["m2"],
        best_params["l1"], best_params["l2"],
        tmax,
        best_params["θ1"], best_params["θ2"],
        best_params["w1"], best_params["w2"]
    )
    println("Simulation completed")
    if debugMode
        println("DEBUG - Simulation info:")
        println("  Total sim points: $(length(x1s_sim))")
        println("  Sim duration: $(ts_sim[end]) s")
        println("  Sim dt: $dt_sim s")
        println("  First 5 sim positions m1: x=$(x1s_sim[1:5]), y=$(y1s_sim[1:5])")
        println("  Video frames: $nbrOfFrames")
        println("  Video duration: $(nbrOfFrames/fps) s")
        println("  Video fps: $fps")
    end
    
    
    # Calculate limits for both plots
    max_len = max(best_params["l1"], best_params["l2"], l1_real_meters, l2_real_meters) * 2.2
    L = max_len
    
    # Create figure with two side-by-side plots
    fig = Figure(size=(1600, 800), figure_padding=10)
    
    # Left plot: Video tracking
    ax_video = Axis(fig[1, 1],
        limits=(-L, L, -L, L),
        aspect=1,
        yreversed=true,  # Try without reversal
        title="Video Tracking",
        xlabel="x (m)",
        ylabel="y (m)")
    
    # Right plot: Optimized simulation
    ax_sim = Axis(fig[1, 2],
        limits=(-L, L, -L, L),
        aspect=1,
        yreversed=false,  # Try without reversal
        title="Optimized Simulation",
        xlabel="x (m)",
        ylabel="y (m)")
    
    # Add parameter information
    dt = 1/30
    w1_start = (θ1s_vid[2] - θ1s_vid[1]) / (dt)
    w2_start = (θ2s_vid[2] - θ2s_vid[1]) / (dt)
    params_text_vid = """
    Optimized Parameters:
    • l1 = $(round(l1*pixel_to_meter*1000, digits=1)) mm
    • l2 = $(round(l2*pixel_to_meter*1000, digits=1)) mm
    • θ1₀ = $(round(rad2deg(θ1s_vid[1]), digits=1))°
    • θ2₀ = $(round(rad2deg(θ2s_vid[1]), digits=1))°
    • ω1₀ = $(round(w1_start, digits=3)) rad/s
    • ω2₀ = $(round(w2_start, digits=3)) rad/s
    """

    params_text_sim = """
    Optimized Parameters:
    • m1 = $(round(best_params["m1"]*1000, digits=2)) g
    • m2 = $(round(best_params["m2"]*1000, digits=2)) g
    • l1 = $(round(best_params["l1"]*1000, digits=1)) mm
    • l2 = $(round(best_params["l2"]*1000, digits=1)) mm
    • θ1₀ = $(round(rad2deg(best_params["θ1"]), digits=1))°
    • θ2₀ = $(round(rad2deg(best_params["θ2"]), digits=1))°
    • ω1₀ = $(round(best_params["w1"], digits=3)) rad/s
    • ω2₀ = $(round(best_params["w2"], digits=3)) rad/s
    """
    
    Label(fig[0, :], "Comparison: Video Tracking vs Optimized Simulation", fontsize=24, font=:bold)
    text!(ax_video, -L*0.6, -L, text=params_text_vid,
          align=(:right, :top), color=:black, fontsize=11,
          space=:data, font="DejaVu Sans Mono")
    text!(ax_sim, L*0.98, L*0.98, text=params_text_sim,
          align=(:right, :top), color=:black, fontsize=11,
          space=:data, font="DejaVu Sans Mono")
    
    # VIDEO TRACKING - Observables
    line1_vid_x = Observable([0.0, 0.0])
    line1_vid_y = Observable([0.0, 0.0])
    line2_vid_x = Observable([0.0, 0.0])
    line2_vid_y = Observable([0.0, 0.0])
    point1_vid = Observable(Point2f(0, 0))
    point2_vid = Observable(Point2f(0, 0))
    
    # VIDEO TRACKING - Trail (last 30 frames)
    trail1_vid = Observable(Point2f[])
    trail2_vid = Observable(Point2f[])
    
    # VIDEO TRACKING - Plot elements
    lines!(ax_video, line1_vid_x, line1_vid_y, color=:blue, linewidth=3, label="Rod 1")
    lines!(ax_video, line2_vid_x, line2_vid_y, color=:red, linewidth=3, label="Rod 2")
    scatter!(ax_video, point1_vid, color=:blue, markersize=20, label="m1")
    scatter!(ax_video, point2_vid, color=:red, markersize=20, label="m2")
    scatter!(ax_video, Point2f(0, 0), color=:green, markersize=15, label="Center")
    lines!(ax_video, trail1_vid, color=(:blue, 0.3), linewidth=1.5)
    lines!(ax_video, trail2_vid, color=(:red, 0.3), linewidth=1.5)
    axislegend(ax_video, position=:lb)
    
    # SIMULATION - Observables
    line1_sim_x = Observable([0.0, 0.0])
    line1_sim_y = Observable([0.0, 0.0])
    line2_sim_x = Observable([0.0, 0.0])
    line2_sim_y = Observable([0.0, 0.0])
    point1_sim = Observable(Point2f(0, 0))
    point2_sim = Observable(Point2f(0, 0))
    
    # SIMULATION - Trail (last 30 frames)
    trail1_sim = Observable(Point2f[])
    trail2_sim = Observable(Point2f[])
    
    # SIMULATION - Plot elements
    lines!(ax_sim, line1_sim_x, line1_sim_y, color=:blue, linewidth=3, label="Rod 1")
    lines!(ax_sim, line2_sim_x, line2_sim_y, color=:red, linewidth=3, label="Rod 2")
    scatter!(ax_sim, point1_sim, color=:blue, markersize=20, label="m1")
    scatter!(ax_sim, point2_sim, color=:red, markersize=20, label="m2")
    scatter!(ax_sim, Point2f(0, 0), color=:green, markersize=15, label="Center")
    lines!(ax_sim, trail1_sim, color=(:blue, 0.3), linewidth=1.5)
    lines!(ax_sim, trail2_sim, color=(:red, 0.3), linewidth=1.5)
    axislegend(ax_sim, position=:lb)
    
    # Time display
    time_label = Label(fig[2, :], "t = 0.00 s", fontsize=18)
    
    # Calculate frame step for simulation
    # Video frame rate vs simulation timestep
    dt_video = 1.0 / fps  # time between video frames
    
    # Calculate how many simulation steps per video frame
    steps_per_frame = round(Int, dt_video / dt_sim)
    
    if debugMode
        println("\nDEBUG - Timing:")
        println("  dt_sim: $dt_sim s")
        println("  dt_video: $dt_video s") 
        println("  Steps per frame: $steps_per_frame")
        println("  Frame 1 should be sim_idx 1")
        println("  Frame 30 should be sim_idx $(30 * steps_per_frame)")
    end

    
    # Pre-calculate simulation indices for each video frame
    sim_indices = [min(1 + (i-1) * steps_per_frame, length(x1s_sim)) for i in 1:nbrOfFrames]
    
    println("  First 10 frame mappings: $(sim_indices[1:10])")
    println("  Last frame maps to: $(sim_indices[end])")
    
    # Update function
    function update_frame(i)
        t = (i-1) / fps
        
        # VIDEO TRACKING UPDATE
        if i <= length(m1_vid_x)
            # Update rods
            line1_vid_x[] = [0.0, m1_vid_x[i]] 
            line1_vid_y[] = [0.0, m1_vid_y[i]]
            line2_vid_x[] = [m1_vid_x[i], m2_vid_x[i]]
            line2_vid_y[] = [m1_vid_y[i], m2_vid_y[i]]
            
            # Update points
            point1_vid[] = Point2f(m1_vid_x[i], m1_vid_y[i])
            point2_vid[] = Point2f(m2_vid_x[i], m2_vid_y[i])
            
            # Update trails (last 30 frames)
            trail_start = max(1, i-30)
            trail1_vid[] = [Point2f(m1_vid_x[j], m1_vid_y[j]) for j in trail_start:i]
            trail2_vid[] = [Point2f(m2_vid_x[j], m2_vid_y[j]) for j in trail_start:i]
        end
        
        # SIMULATION UPDATE - now 1:1 mapping with video frames
        sim_idx = i  # Direct mapping since both have same number of points
        if sim_idx > 0 && sim_idx <= length(x1s_sim)
            # Update rods
            line1_sim_x[] = [0.0, x1s_sim[sim_idx]]
            line1_sim_y[] = [0.0, y1s_sim[sim_idx]]
            line2_sim_x[] = [x1s_sim[sim_idx], x2s_sim[sim_idx]]
            line2_sim_y[] = [y1s_sim[sim_idx], y2s_sim[sim_idx]]
            
            # Update points
            point1_sim[] = Point2f(x1s_sim[sim_idx], y1s_sim[sim_idx])
            point2_sim[] = Point2f(x2s_sim[sim_idx], y2s_sim[sim_idx])
            
            # Update trails (last 30 frames)
            trail_start_idx = max(1, sim_idx - 30)
            trail1_sim[] = [Point2f(x1s_sim[j], y1s_sim[j]) for j in trail_start_idx:sim_idx]
            trail2_sim[] = [Point2f(x2s_sim[j], y2s_sim[j]) for j in trail_start_idx:sim_idx]
        end
        
        # Update time
        time_label.text[] = "Frame $i/$nbrOfFrames"

    end
    
    # Record animation with better error handling
    println("\nRecording comparison video...")
    println("Output: $output_file")
    println("FPS: $fps")
    println("Total frames: $nbrOfFrames")
    
    try
        # Try with compression and format options to reduce write issues
        @time record(fig, "videos/$(output_file)", 1:nbrOfFrames; 
                    framerate=fps,
                    compression=20,  # Lower compression for faster writes
                    format="mp4") do i
            update_frame(i)
            
            # Add progress indicator every 20 frames
            if i % 20 == 0
                println("  Progress: $(round(i/nbrOfFrames*100, digits=1))% ($i/$nbrOfFrames frames)")
            end
        end
        
        println("\n" * "-"^60)
        println("COMPARISON VIDEO CREATED")
        println("Saved as: $output_file")
        println("-"^60)
        
    catch e
        println("\nError during video recording: $e")
        println("\nTrying alternative approach: saving individual frames first...")
        
        # Alternative: save as individual PNG frames, then combine
        frames_dir = "temp_frames"
        if !isdir(frames_dir)
            mkdir(frames_dir)
        end
        
        println("Saving frames to $frames_dir...")
        for i in 1:nbrOfFrames
            update_frame(i)
            save(joinpath(frames_dir, "frame_$(lpad(i, 4, '0')).png"), fig)
            
            if i % 20 == 0
                println("  Saved: $(round(i/nbrOfFrames*100, digits=1))% ($i/$nbrOfFrames frames)")
            end
        end
    end
    
    return fig
end