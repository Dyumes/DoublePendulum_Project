# Veuillet Gaëtan
# Double pendulum - Computer Physics 1
# 2025
# Description : Script to process video frames and create an animation of the double pendulum motion. The main goal
# is to detect the positions of two masses in a video, to use these positions to compare with the simulations -> prediction + finding right masses.

using GLMakie
using FileIO
using VideoIO
using GeometryBasics
using Colors
using ImageMorphology
using Statistics

import GLMakie: scatter!

function video_analysis_and_animation(video_path::String, nbrOfFrames)

    video = VideoIO.openvideo(video_path)
    frames = []

    #Nbr of frames of the video = 200
    nbrOfFrames = nbrOfFrames

    #List all the frames in an array
    try
        i = 0
        while !eof(video)
            push!(frames, read(video))
            i += 1
            #ONLY FOR DEBUGGING PURPOSES
            #println("Frame $i read")

            if i >= nbrOfFrames
                break
            end
        end
    finally
        close(video)
    end

    select_frame = 1

    img = frames[select_frame]

    #image x and y
    imgX = size(img, 2)
    imgY = size(img, 1)

    f = Figure()

    #Rotate once and reuse
    rotated_img = rotr90(img)
    imgplot = image(f[1, 1], rotated_img,
        axis = (aspect = DataAspect(), title = "rotr90",))
    ax = imgplot.axis

    #Orange mask for detection
    function orange_mask(img)
        hsv = HSV.(img)
        mask = map(c -> (10 <= c.h <= 35) && (c.s >= 0.5) && (0.4 <= c.v <= 0.8), hsv)
        area_opening(Int.(mask), min_area=50)
    end

    #Extract centroids from mask => positions of masses
    function centroids_from_mask(mask)
        labels = label_components(mask)
        cents = Tuple{Float64, Float64}[]
        for l in 1:maximum(labels)
            inds = findall(labels .== l)
            if !isempty(inds)
                ys = [Tuple(I)[1] for I in inds]
                xs = [Tuple(I)[2] for I in inds]
                push!(cents, (mean(xs), mean(ys)))
            end
        end
        sort!(cents, by = c -> c[2]) #First sort by y position (top to bottom)
        return cents
    end

    pos_swap = []

    function detect_centroids(img)
        mask = orange_mask(img)
        pos = centroids_from_mask(mask)
        #println("Positions détectées : ", pos)
        push!(pos_swap, [(pos[1][2], pos[1][1]), (pos[2][2], pos[2][1])])
        return centroids_from_mask(mask)
    end

    print("Processing frames... May takes a few minutes...\n")

    try 
        for frame in 1:1:length(frames)
            #ONLY FOR DEBUGGING PURPOSES
            #print("Processing frame $(frame)/$(length(frames))...\n")
            rotated_img = rotr90(frames[frame])
            detect_centroids(rotated_img)
        end
    finally
        print("Finished processing all frames.\n")
    end

    function dist_2(p1::Tuple{Float64, Float64}, p2::Tuple{Float64, Float64})
        return sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)
    end

    #Reorder the detected positions to maintain consistency between frames and masses
    function reorder_positions(positions)
        reordered = [positions[1]]  #First frame as reference

        for i in 2:length(positions)
            prev = reordered[end]
            cur = positions[i]

            #Compare distances to decide if we need to swap
            if length(cur) == length(prev) == 2
                if dist_2(cur[1], prev[1]) + dist_2(cur[2], prev[2]) >
                dist_2(cur[2], prev[1]) + dist_2(cur[1], prev[2])
                    cur = [cur[2], cur[1]]  #swap if it minimize the distance
                end
            end
            push!(reordered, cur)
        end

        return reordered
    end

    #Function to find the center point given three points (medianes intersection)
    function find_center_point(p1, p2, p3)
        d = 2*(p1[1]*(p2[2]-p3[2]) + p2[1]*(p3[2]-p1[2]) + p3[1]*(p1[2]-p2[2]))
        center_x = ((p1[1]^2 + p1[2]^2)*(p2[2]-p3[2]) + (p2[1]^2 + p2[2]^2)*(p3[2]-p1[2]) + (p3[1]^2 + p3[2]^2)*(p1[2]-p2[2])) / d
        center_y = ((p1[1]^2 + p1[2]^2)*(p3[1]-p2[1]) + (p2[1]^2 + p2[2]^2)*(p1[1]-p3[1]) + (p3[1]^2 + p3[2]^2)*(p2[1]-p1[1])) / d
        return (center_x, center_y)
    end


    pos_swap = reorder_positions(pos_swap)

    #Get all the positions of m1 and m2
    m1_positions = [Point2f(pos[2][1], pos[2][2]) for pos in pos_swap]
    m2_positions = [Point2f(pos[1][1], pos[1][2]) for pos in pos_swap]

    centre = find_center_point(m1_positions[1], m1_positions[Int(nbrOfFrames/2)], m1_positions[nbrOfFrames])

    #Basic function to calculate the lengths of the rodes
    function calculate_rodes_length()
        l1 = sqrt((m1_positions[1][1] - centre[1])^2 + 
                (m1_positions[1][2] - centre[2])^2)
        l2 = sqrt((m1_positions[1][1] - m2_positions[1][1])^2 + 
                (m1_positions[1][2] - m2_positions[1][2])^2)
        return l1, l2
    end


    l1, l2 = calculate_rodes_length()

    rapport_rode = l1 / l2

    #ONLY FOR DEBUGGING PURPOSES
    #println("Centre: ($(centre[1]), $(centre[2]))")
    #println("Rode 1 length l1 (m1-m2): $l1) pixels")
    #println("Rode 2 length l2 (centre-m1): $(l2) pixels")
    #println("Rapport l1/l2: $(round(rapport_rode, digits=3))")

    #Show lengths info on the animation
    info_text = """
    Rodes lengths information:
    l1 (centre-m1): $(l1) px
    l2 (m1-m2): $(l2) px
    Rapport: $(rapport_rode)
    """

    #ANIMATION WITH GLMAKIE
    println("\nCreating the animation...")

    #Average lengths for scaling
    fig = Figure(size=(1400, 800))

    #First figure : Video with the points detected
    ax_video = Axis(fig[1, 1],
                    title="Detection of masses",
                    aspect=DataAspect(),
                    width=600, height=800)

    #Second figure : Trajectories of the masses on the plot
    ax_traj = Axis(fig[1, 2],
                    limits = (0, imgX, 0, imgY),
                title="Masses trajectories",
                xlabel="Position X",
                ylabel="Position Y",
                aspect=DataAspect(),
                width=600, height=800)

    #VIDEO PART
    #Show the first image
    rotated_img = rotr90(frames[1])
    img_obs = Observable(rotated_img)
    image!(ax_video, img_obs)

    #Observables for the masses positions in the video
    m1_video = Observable(m1_positions[1])
    m2_video = Observable(m2_positions[1])

    #Scatter the masses points and center in the video
    scatter!(ax_video, m1_video, color=:red, markersize=15, label="Masse 1")
    scatter!(ax_video, m2_video, color=:blue, markersize=15, label="Masse 2")
    scatter!(ax_video, Point2f(centre[1], centre[2]), color=:green, markersize=15, label="Center")
    axislegend(ax_video, position=:rb)

    #TRAJECTORIES GRAPH PART
    #Observables for the trajectories
    traj1_obs = Observable(Point2f[])
    traj2_obs = Observable(Point2f[])

    #Observables for the current positions
    m1_current = Observable(m1_positions[1])
    m2_current = Observable(m2_positions[1])

    #Trace the trajectories
    lines!(ax_traj, traj1_obs, color=(:red, 0.5), linewidth=2, label="M1 Trajectory")
    lines!(ax_traj, traj2_obs, color=(:blue, 0.5), linewidth=2, label="M2 Trajectory")

    #Current points
    scatter!(ax_traj, m1_current, color=:red, markersize=15, label="Masse 1")
    scatter!(ax_traj, m2_current, color=:blue, markersize=15, label="Masse 2")
    scatter!(ax_traj, Point2f(centre[1], centre[2]), color=:green, markersize=15, label="Center")

    #Show lengths info on the trajectory graph
    text!(ax_traj, 0.05, 0.95, text=info_text,
        align=(:left, :top), color=:black, fontsize=12,
        space=:relative)

    axislegend(ax_traj, position=:rb)

    # Add the rodes between the masses and the center
    rode1_x = Observable([0.0, 0.0])
    rode1_y = Observable([0.0, 0.0])
    rode2_x = Observable([0.0, 0.0])
    rode2_y = Observable([0.0, 0.0])

    lines!(ax_traj, rode1_x, rode1_y, color=:black, linewidth=2)
    lines!(ax_traj, rode2_x, rode2_y, color=:black, linewidth=2)

    #ANIMATION UPDATE FUNCTIOn
    function update_frame(i)

        img_obs[] = rotr90(frames[i])
        
        #Limit the index to avoid out of bounds (our quantity of disponible data)
        idx = min(i, length(m1_positions))
        
        #-Update in the video-
        #positions of the masses
        m1_video[] = m1_positions[idx]
        m2_video[] = m2_positions[idx]
        
        #the trajectories (keep the last 50 points for beautiful effect :D)
        start_idx = max(1, idx-50)
        traj1_obs[] = m1_positions[start_idx:idx]
        traj2_obs[] = m2_positions[start_idx:idx]
        
        #current positions
        m1_current[] = m1_positions[idx]
        m2_current[] = m2_positions[idx]
        
        #Rodes
        rode1_x[] = [centre[1], m1_current[][1]]
        rode1_y[] = [centre[2], m1_current[][2]]
        rode2_x[] = [m1_current[][1], m2_current[][1]]
        rode2_y[] = [m1_current[][2], m2_current[][2]]
        
        # Mettre à jour les titres
        ax_video.title[] = "Video with detection - Frame $i/$nbrOfFrames"
        ax_traj.title[] = "Trajectories - Frame $i/$nbrOfFrames"
    end

    #ANIMATION CREATION AND SAVING
    println("saving animation...")
    nframes = min(length(m1_positions), length(frames))

    @time record(fig, "videos/pendulum_video_trajectories.mp4", 1:nframes;
                framerate=30) do i
        update_frame(i)
    end

    println("Amimation saved as 'pendulum_video_trajectories.mp4'")

    #INTERACTIVE VISUALISATION
    println("\nCreating the visualisation...")

    fig_interactive = Figure(size=(1200, 600))
    ax1_inter = Axis(fig_interactive[1, 1], limits = (0, imgX, 0, imgY), title="Realtime detection", aspect=DataAspect())
    ax2_inter = Axis(fig_interactive[1, 2], limits = (0, imgX, 0, imgY), title="Trajectoires", aspect=DataAspect())

    #Observables for interactive vizualisation
    img_inter = Observable(rotr90(frames[1]))
    m1_inter = Observable(m1_positions[1])
    m2_inter = Observable(m2_positions[1])
    traj1_inter = Observable(Point2f[])
    traj2_inter = Observable(Point2f[])
    rode1_x_inter = Observable([0.0, 0.0])
    rode1_y_inter = Observable([0.0, 0.0])
    rode2_x_inter = Observable([0.0, 0.0])
    rode2_y_inter = Observable([0.0, 0.0])

    #Graphical elements
    image!(ax1_inter, img_inter)
    scatter!(ax1_inter, m1_inter, color=:red, markersize=15)
    scatter!(ax1_inter, m2_inter, color=:blue, markersize=15)
    lines!(ax2_inter, traj1_inter, color=(:red, 0.5), linewidth=2)
    lines!(ax2_inter, traj2_inter, color=(:blue, 0.5), linewidth=2)
    scatter!(ax2_inter, m1_inter, color=:red, markersize=20)
    scatter!(ax2_inter, m2_inter, color=:blue, markersize=20)
    lines!(ax2_inter, rode1_x_inter, rode1_y_inter, color=:black, linewidth=2)
    lines!(ax2_inter, rode2_x_inter, rode2_y_inter, color=:black, linewidth=2)
    scatter!(ax1_inter, Point2f(centre[1], centre[2]), color=:green, markersize=15, label="Center")
    scatter!(ax2_inter, Point2f(centre[1], centre[2]), color=:green, markersize=15, label="Center")

    #Show lengths info on the interactive plot
    text!(ax2_inter, 0.05, 0.95, text=info_text,
        align=(:left, :top), color=:black, fontsize=12,
        space=:relative)

    #TODO : frame numebr not changing at the same time ? 
    #Slider to navigate through frames
    frame_slider = Slider(fig_interactive[2, :], range=1:nframes, startvalue=1)
    current_frame = frame_slider.value

    #Update function for interactive vizualisation
    on(current_frame) do frame_idx
        idx = Int(round(frame_idx))
        idx = clamp(idx, 1, nframes)
        
        img_inter[] = rotr90(frames[idx])
        m1_inter[] = m1_positions[idx]
        m2_inter[] = m2_positions[idx]
        
        #Trajectories
        traj1_inter[] = m1_positions[1:idx]
        traj2_inter[] = m2_positions[1:idx]
        
        #Rodes
        rode1_x_inter[] = [centre[1], m1_inter[][1]]
        rode1_y_inter[] = [centre[2], m1_inter[][2]]
        rode2_x_inter[] = [m1_inter[][1], m2_inter[][1]]
        rode2_y_inter[] = [m1_inter[][2], m2_inter[][2]]
        
        ax1_inter.title[] = "Frame $idx/$nframes"
    end

    Label(fig_interactive[2, :], "Frame: $(current_frame[])")
    display(fig_interactive)

    println("interactive vizualition ready.")

    theta1s = Float64[]
    theta2s = Float64[]


    
    for i in 1:length(m1_positions)
        dx1 = m1_positions[i][1] - centre[1]
        dy1 = m1_positions[i][2] - centre[2]
        θ1 = atan(dy1, dx1) + pi/2
        push!(theta1s, θ1)

        dx2 = m2_positions[i][1] - m1_positions[i][1]
        dy2 = m2_positions[i][2] - m1_positions[i][2]
        θ2 = atan(dy2, dx2) + pi/2
        push!(theta2s, θ2)
    end

    return frames, m1_positions, m2_positions, centre, l1, l2, theta1s, theta2s
end