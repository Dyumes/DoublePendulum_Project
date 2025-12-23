using GLMakie
using FileIO
using VideoIO
using GeometryBasics
using Colors
using ImageMorphology
using Statistics


using VideoIO

video = VideoIO.openvideo("First_Video_2s.mp4")
frames = []

try
    i = 0
    while !eof(video)
        push!(frames, read(video))
        i += 1
        println("Frame $i read")

        if i >= 20
            break
        end
    end
finally
    close(video)
end

# frames[1], frames[2], ...
select_frame = 1

img = frames[select_frame]

#image x and y
imgX = size(img, 2)
imgY = size(img, 1)

f = Figure()

# rotate once and reuse
rotated_img = rotr90(img)
imgplot = image(f[1, 1], rotated_img,
    axis = (aspect = DataAspect(), title = "rotr90",))
ax = imgplot.axis


#m1_pos = Tuple{Float64, Float64}[]
#m2_pos = Tuple{Float64, Float64}[]

# --- Masque orange ---
function orange_mask(img)
    hsv = HSV.(img)
    mask = map(c -> (10 <= c.h <= 35) && (c.s >= 0.5) && (0.4 <= c.v <= 0.8), hsv)
    area_opening(Int.(mask), min_area=50)
end

#mask = orange_mask(rotated_img)

# --- Extraire les centroïdes ---
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
    sort!(cents, by = c -> c[2]) # tri par hauteur (m1 en haut, m2 en bas)
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

print("Processing frames...\n")

try 
    for frame in 1:1:length(frames)
        print("Processing frame $(frame)/$(length(frames))...\n")
        rotated_img = rotr90(frames[frame])
        #image!(ax, rotated_img)
        detect_centroids(rotated_img)
        #scatter!(ax, [pos_swap[frame][1][1], pos_swap[frame][2][1]],[pos_swap[frame][1][2],pos_swap[frame][2][2]], markersize=12, color=:red)
        #display(f)
        #sleep(0.1)
    end
finally
    print("Finished processing all frames.\n")
end

function dist_2(p1::Tuple{Float64, Float64}, p2::Tuple{Float64, Float64})
    return sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)
end

function reorder_positions(positions)
    reordered = [positions[1]]  # première frame comme référence

    for i in 2:length(positions)
        prev = reordered[end]
        cur = positions[i]

        # Comparer les distances et réordonner pour correspondre au mieux
        if length(cur) == length(prev) == 2
            if dist_2(cur[1], prev[1]) + dist_2(cur[2], prev[2]) >
               dist_2(cur[2], prev[1]) + dist_2(cur[1], prev[2])
                cur = [cur[2], cur[1]]  # swap si ça minimise la distance totale
            end
        end
        push!(reordered, cur)
    end

    return reordered
end

pos_swap = reorder_positions(pos_swap)

m1_positions = [pos[1] for pos in pos_swap]  # position de la masse 1 frame par frame
m2_positions = [pos[2] for pos in pos_swap]  # position de la masse 2 frame par frame


#=ONLY TO DISPLAY FRAME BY FRAME AND CHECK POINTS
try
    for frame in 1:1:length(frames)
        rotated_img = rotr90(frames[frame])
        image!(ax, rotated_img)
        scatter!(ax, [pos_swap[frame][1][1], pos_swap[frame][2][1]],[pos_swap[frame][1][2],pos_swap[frame][2][2]], markersize=12, color=:red)
        display(f)
        sleep(0.01)
    end
finally
    print("Finished displaying all frames.\n")
end
=#

#simple plot anim
#=Plots.plot([pos_swap[1][1][1] for i in 1:length(pos_swap)],
           [pos_swap[1][1][2] for i in 1:length(pos_swap)],
           label="Mass 1 Trajectory", xlabel="X Position", ylabel="Y Position", title="Trajectory of Mass 1")

=#
#TODO : HAS TO REPLACE FIRST 1s BY select_frame
#scatter!(ax, [pos_swap[1][1][1], pos_swap[1][2][1]],[pos_swap[1][1][2],pos_swap[1][2][2]], markersize=12, color=:red)

x_init = 56
y_init = 78

#center = [imgX/2, imgY/2]
centre = [0,0]
m1 = [centre[1] - 9, centre[2] + 440]
m2 = [m1[1] - 30, m1[2] + 320]

l1 = sqrt((m1[1] - centre[1])^2 + (m1[2] - centre[2])^2)#dist entre m1 et centre
println("Longueur l1 [M]: $l1")
l2 = sqrt((m2[1] - m1[1])^2 + (m2[2] - m1[2])^2)
println("Longueur l2 : $l2")



rapportRode = l1/l2

println("Rapport des rodes : l2 = 1, l1 = $rapportRode")

resizeL1 = 0.04#environ 4cm l1 en vrai
resizleL2 = 0.04 / rapportRode * 1

println("resizeL1 = $resizeL1")
println("resizleL2 = $resizleL2")

cos_teta1 = 440/l1#cosadhyp
teta1 = acos(cos_teta1)
println("Teta 1 [RAD] = $teta1")
cos_teta2 = 320/l2
teta2 = acos(cos_teta2)
println("Teta 2 = $teta2")

