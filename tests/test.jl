using GLMakie
using FileIO
using VideoIO
using GeometryBasics
using Colors
using ImageMorphology
using Statistics

video = VideoIO.openvideo("First_Video_2s.mp4")
frames = []

nbrOfFrames = 30

try
    i = 0
    while !eof(video)
        push!(frames, read(video))
        i += 1
        println("Frame $i read")

        if i >= nbrOfFrames
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

# --- Masque orange ---
function orange_mask(img)
    hsv = HSV.(img)
    mask = map(c -> (10 <= c.h <= 35) && (c.s >= 0.5) && (0.4 <= c.v <= 0.8), hsv)
    area_opening(Int.(mask), min_area=50)
end

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
        detect_centroids(rotated_img)
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

function find_center_point(p1, p2, p3)
    d = 2*(p1[1]*(p2[2]-p3[2]) + p2[1]*(p3[2]-p1[2]) + p3[1]*(p1[2]-p2[2]))
    center_x = ((p1[1]^2 + p1[2]^2)*(p2[2]-p3[2]) + (p2[1]^2 + p2[2]^2)*(p3[2]-p1[2]) + (p3[1]^2 + p3[2]^2)*(p1[2]-p2[2])) / d
    center_y = ((p1[1]^2 + p1[2]^2)*(p3[1]-p2[1]) + (p2[1]^2 + p2[2]^2)*(p1[1]-p3[1]) + (p3[1]^2 + p3[2]^2)*(p2[1]-p1[1])) / d
    return (center_x, center_y)
end


pos_swap = reorder_positions(pos_swap)

#Extraire les positions de m1 et m2
m1_positions = [Point2f(pos[2][1], pos[2][2]) for pos in pos_swap]
m2_positions = [Point2f(pos[1][1], pos[1][2]) for pos in pos_swap]

centre = find_center_point(m1_positions[1], m1_positions[Int(nbrOfFrames/2)], m1_positions[nbrOfFrames])

#=
# Calculer les longueurs moyennes sur toutes les frames
function calculate_average_lengths()
    total_l1 = 0.0
    total_l2 = 0.0
    n = length(m1_positions)
    
    for i in 1:n
        # Longueur entre m1 et m2 (l1)
        l1 = sqrt((m1_positions[i][1] - m2_positions[i][1])^2 + 
                  (m1_positions[i][2] - m2_positions[i][2])^2)
        total_l1 += l1
        
        # Pour l2, on a besoin du centre
        # On calcule le centre comme le point moyen de tous les points de m1
        # ou on peut utiliser le premier point comme centre fixe
    end
    
    avg_l1 = total_l1 / n
    
    # Pour l2, on calcule la distance moyenne du premier point m1 au centre
    # Le centre est estimé comme la position moyenne de m1
    center_x = mean([pos[1] for pos in m1_positions])
    center_y = mean([pos[2] for pos in m1_positions])

    total_l2 = 0.0
    for i in 1:n
        l2 = sqrt((m1_positions[i][1] - centre[1])^2 + 
                  (m1_positions[i][2] - centre[2])^2)
        total_l2 += l2
    end
    
    avg_l2 = total_l2 / n
    
    return centre, avg_l1, avg_l2
end
=#

function calculate_rodes_length()
    l1 = sqrt((m1_positions[1][1] - centre[1])^2 + 
              (m1_positions[1][2] - centre[2])^2)
    l2 = sqrt((m1_positions[1][1] - m2_positions[1][1])^2 + 
              (m1_positions[1][2] - m2_positions[1][2])^2)
    return l1, l2
end

# Calculer les longueurs moyennes
#centre, avg_l1, avg_l2 = calculate_average_lengths()

l1, l2 = calculate_rodes_length()

# Calculer le rapport
#rapport_rode = avg_l1 / avg_l2

rapport_rode = l1 / l2

#println("Centre estimé: ($(centre[1]), $(centre[2]))")
#println("Longueur moyenne l1 (m1-m2): $(round(avg_l1, digits=2)) pixels")
#println("Longueur moyenne l2 (centre-m1): $(round(avg_l2, digits=2)) pixels")
#println("Rapport l1/l2: $(round(rapport_rode, digits=3))")

println("Centre: ($(centre[1]), $(centre[2]))")
println("Rode 1 length l1 (m1-m2): $l1) pixels")
println("Rode 2 length l2 (centre-m1): $(l2) pixels")
println("Rapport l1/l2: $(round(rapport_rode, digits=3))")

# Afficher les informations sur le graphique
info_text = """
Rodes lengths information:
l1 (m1-m2): $(l1) px
l2 (centre-m2): $(l2) px
Rapport: $(rapport_rode)
"""

# === PARTIE 2: Animation avec GLMakie ===
println("\nCreating the animation...")

# Créer la figure (taille fixe pour vidéo + trajectoire)
# On force une résolution plus large pour que le subplot vidéo soit nettement plus grand
fig = Figure(size=(1400, 800))

max_len = avg_l1 + avg_l2 #lengths rode
L = 1.1 * max_len
# Première sous-figure : Vidéo avec les points détectés
ax_video = Axis(fig[1, 1],
                title="Detection of masses",
                aspect=DataAspect(),
                width=600, height=800)

# Deuxième sous-figure : Animation des trajectoires
ax_traj = Axis(fig[1, 2],
                limits = (0, imgX, 0, imgY),
               title="Masses trajectory",
               xlabel="Position X",
               ylabel="Position Y",
               aspect=DataAspect(),
               width=600, height=800)

# === Pour l'axe vidéo ===
# Afficher la première image
rotated_img = rotr90(frames[1])
img_obs = Observable(rotated_img)
image!(ax_video, img_obs)

# Observables pour les points dans la vidéo
m1_video = Observable(m1_positions[1])
m2_video = Observable(m2_positions[1])

# Scatter plots pour les points dans la vidéo
scatter!(ax_video, m1_video, color=:red, markersize=15, label="Masse 1")
scatter!(ax_video, m2_video, color=:blue, markersize=15, label="Masse 2")
scatter!(ax_video, Point2f(centre[1], centre[2]), color=:green, markersize=10, label="Center")
axislegend(ax_video, position=:rb)

# === Pour l'axe trajectoires ===
# Observables pour les trajectoires
traj1_obs = Observable(Point2f[])
traj2_obs = Observable(Point2f[])

# Observables pour les positions courantes
m1_current = Observable(m1_positions[1])
m2_current = Observable(m2_positions[1])

# Tracer les trajectoires
lines!(ax_traj, traj1_obs, color=(:red, 0.5), linewidth=2, label="M1 Trajectory")
lines!(ax_traj, traj2_obs, color=(:blue, 0.5), linewidth=2, label="M2 Trajectory")

# Points courants
scatter!(ax_traj, m1_current, color=:red, markersize=20, label="Masse 1")
scatter!(ax_traj, m2_current, color=:blue, markersize=20, label="Masse 2")
scatter!(ax_traj, Point2f(centre[1], centre[2]), color=:green, markersize=10, label="Center")

# Ajouter les informations des longueurs sur le graphique
text!(ax_traj, 0.05, 0.95, text=info_text,
      align=(:left, :top), color=:black, fontsize=12,
      space=:relative)

axislegend(ax_traj, position=:rb)

# Ajouter les barres (rodes) entre les points
rode1_x = Observable([0.0, 0.0])
rode1_y = Observable([0.0, 0.0])
rode2_x = Observable([0.0, 0.0])
rode2_y = Observable([0.0, 0.0])

lines!(ax_traj, rode1_x, rode1_y, color=:black, linewidth=2)
lines!(ax_traj, rode2_x, rode2_y, color=:black, linewidth=2)

# === Fonction de mise à jour pour l'animation ===
function update_frame(i)

    img_obs[] = rotr90(frames[i])
    
    # Limiter l'index aux données disponibles
    idx = min(i, length(m1_positions))
    
    # Mettre à jour les points dans la vidéo
    m1_video[] = m1_positions[idx]
    m2_video[] = m2_positions[idx]
    
    # Mettre à jour les trajectoires (garder les 50 derniers points)
    start_idx = max(1, idx-50)
    traj1_obs[] = m1_positions[start_idx:idx]
    traj2_obs[] = m2_positions[start_idx:idx]
    
    # Mettre à jour les positions courantes
    m1_current[] = m1_positions[idx]
    m2_current[] = m2_positions[idx]
    
    # Mettre à jour les barres (rodes) avec le centre fixe calculé
    rode1_x[] = [centre[1], m1_current[][1]]
    rode1_y[] = [centre[2], m1_current[][2]]
    rode2_x[] = [m1_current[][1], m2_current[][1]]
    rode2_y[] = [m1_current[][2], m2_current[][2]]
    
    # Mettre à jour les titres
    ax_video.title[] = "Video with detection - Frame $i/$nbrOfFrames"
    ax_traj.title[] = "Trajectories - Frame $i/$nbrOfFrames"
    
    # Les limites de `ax_traj` sont fixes (définies au départ) pour garder
    # une taille constante de la trajectoire dans la vidéo enregistrée.
    # (On évite le recalcul automatique des limites ici.)
end

# === Créer l'animation ===
println("saving animation...")
nframes = min(length(m1_positions), length(frames))

@time record(fig, "pendulum_video_trajectories.mp4", 1:nframes;
             framerate=30) do i
    update_frame(i)
end

println("Amimation saved as 'pendulum_video_trajectories.mp4'")

# === Optionnel : Afficher une visualisation interactive ===
println("\nCreating the visualisation...")

fig_interactive = Figure(size=(1200, 600))
ax1_inter = Axis(fig_interactive[1, 1], title="Realtime detection", aspect=DataAspect())
ax2_inter = Axis(fig_interactive[1, 2], title="Trajectoires", aspect=DataAspect())

# Observables pour l'interactive
img_inter = Observable(rotr90(frames[1]))
m1_inter = Observable(m1_positions[1])
m2_inter = Observable(m2_positions[1])
traj1_inter = Observable(Point2f[])
traj2_inter = Observable(Point2f[])
rode1_x_inter = Observable([0.0, 0.0])
rode1_y_inter = Observable([0.0, 0.0])
rode2_x_inter = Observable([0.0, 0.0])
rode2_y_inter = Observable([0.0, 0.0])

# Graphiques
image!(ax1_inter, img_inter)
scatter!(ax1_inter, m1_inter, color=:red, markersize=15)
scatter!(ax1_inter, m2_inter, color=:blue, markersize=15)
lines!(ax2_inter, traj1_inter, color=(:red, 0.5), linewidth=2)
lines!(ax2_inter, traj2_inter, color=(:blue, 0.5), linewidth=2)
scatter!(ax2_inter, m1_inter, color=:red, markersize=20)
scatter!(ax2_inter, m2_inter, color=:blue, markersize=20)
lines!(ax2_inter, rode1_x_inter, rode1_y_inter, color=:black, linewidth=2)
lines!(ax2_inter, rode2_x_inter, rode2_y_inter, color=:black, linewidth=2)

# Ajouter les informations des longueurs sur le graphique interactif
text!(ax2_inter, 0.05, 0.95, text=info_text,
      align=(:left, :top), color=:black, fontsize=12,
      space=:relative)

# Slider pour naviguer
frame_slider = Slider(fig_interactive[2, :], range=1:nframes, startvalue=1)
current_frame = frame_slider.value

# Mise à jour lors du changement de slider
on(current_frame) do frame_idx
    idx = Int(round(frame_idx))
    idx = clamp(idx, 1, nframes)
    
    img_inter[] = rotr90(frames[idx])
    m1_inter[] = m1_positions[idx]
    m2_inter[] = m2_positions[idx]
    
    # Trajectoires cumulatives
    traj1_inter[] = m1_positions[1:idx]
    traj2_inter[] = m2_positions[1:idx]
    
    # Mettre à jour les rodes avec le centre fixe
    rode1_x_inter[] = [centre[1], m1_inter[][1]]
    rode1_y_inter[] = [centre[2], m1_inter[][2]]
    rode2_x_inter[] = [m1_inter[][1], m2_inter[][1]]
    rode2_y_inter[] = [m1_inter[][2], m2_inter[][2]]
    
    ax1_inter.title[] = "Frame $idx/$nframes"
end

Label(fig_interactive[2, :], "Frame: $(current_frame[])")
display(fig_interactive)

println("interactive vizualition ready.")