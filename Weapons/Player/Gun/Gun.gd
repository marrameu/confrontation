extends Spatial

# Shooting
var shoot_range := 500
var camera_width_center := 0.0
var camera_height_center := 0.0
var shoot_origin := Vector3()
var shoot_normal := Vector3()

# Particles
const hit_scene = preload("res://Bullets/Particles/HitParticles.tscn")

# Multiplayer
var action := ""

func _ready() -> void:
	# $AudioStreamPlayer3D.translation = get_node("../../").translation
	pass

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not is_network_master():
			$HUD/Crosshair.hide()
			$HUD/Hitmarker.hide()
			return
	
	if action == "":
		action = get_parent().shoot_action
		return
	
	if Input.is_action_just_pressed(action):
		($Timer as Timer).start()
	elif not Input.is_action_pressed(action):
		($Timer as Timer).stop()
		var current_cam = ProjectSettings.get("player" + String(get_node("../..").number_of_player) + "_camera")
		if current_cam:
			current_cam.get_parent().stop_shake_camera()

func shoot() -> void:
	# Sound
	if get_tree().has_network_peer():
		if is_network_master():
			$AudioStreamPlayer3D.play()
	else:
		$AudioStreamPlayer3D.play()
	
	# Shake Camera
	var current_cam = ProjectSettings.get("player" + String(get_node("../..").number_of_player) + "_camera")
	current_cam.get_parent().shake_camera() 
	
	# RayCast
	var space_state = get_world().direct_space_state
	
	if current_cam:
		var viewport = get_node("/root/Main/Splitscreen")._renders[get_node("../..").number_of_player - 1].viewport
		camera_width_center = viewport.get_visible_rect().size.x / 2
		camera_height_center = viewport.get_visible_rect().size.y / 2
		
		shoot_origin = current_cam.project_ray_origin(Vector2(camera_width_center, camera_height_center))
		shoot_normal = shoot_origin + current_cam.project_ray_normal(Vector2(camera_width_center, camera_height_center)) * shoot_range
		
		var result = space_state.intersect_ray(shoot_origin, shoot_normal, [])
		if result:
			if get_tree().has_network_peer():
				rpc("hit", result.collider.get_path(), result.position)
			else:
				hit(result.collider.get_path(), result.position)

func _on_Timer_timeout() -> void:
	shoot()

# Millorar per l'online, si no es el servidor no té que fer tots els calculs?
sync func hit(collider_path : NodePath, point : Vector3) -> void:
	var hit : Particles = hit_scene.instance()
	get_node("/root/Main").add_child(hit)
	hit.global_transform.origin = point
	
	if not get_node(collider_path):
		return
	var collider : CollisionObject = get_node(collider_path)
	if collider.is_in_group("Players") or collider.is_in_group("Troops"):
		if collider.get_node("TroopManager").m_team != get_node("../../TroopManager").m_team:
			var damage := 40
			if point.y > collider.get_global_transform().origin.y + 0.85:
				damage = 40
				$HUD/Hitmarker.texture = preload("res://Interface/Hitmarkers/hitmarker_yellow.png")
				$HUD/HitmarkerTimer.start()
			else:
				damage = 20 
				$HUD/Hitmarker.texture = preload("res://Interface/Hitmarkers/hitmarker.png")
				$HUD/HitmarkerTimer.start()
			
			if get_tree().has_network_peer():
				if get_tree().is_network_server():
					collider.get_node("HealthSystem").rpc("take_damage", damage)
			else:
				collider.get_node("HealthSystem").take_damage(damage)
			
			if get_tree().has_network_peer():
				if not is_network_master():
					return
			
			# El servidor li té que dir si l'ha matat
			var current_life := 0
			if get_tree().has_network_peer():
				if get_tree().is_network_server():
					current_life = collider.get_node("HealthSystem").health
				else:
					current_life = collider.get_node("HealthSystem").health - damage
			else:
				current_life = collider.get_node("HealthSystem").health
			
			if current_life <= 0:
				$HUD/AudioStreamPlayer.play()
				$HUD/Hitmarker.texture = preload("res://Interface/Hitmarkers/hitmarker_red.png")

func _on_HitmarkerTimer_timeout():
	$HUD/Hitmarker.texture = null
