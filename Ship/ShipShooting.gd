extends Spatial

var shoot_range := 1500
var camera_width_center := 0.0
var camera_height_center := 0.0
var shoot_origin := Vector3()
var shoot_normal := Vector3()
var shoot_target := Vector3()

# Bullets
onready var bullet_scene : PackedScene = preload("res://Bullets/Particles/ShipBullet.tscn")
onready var secondary_bullet_scene : PackedScene = preload("res://Bullets/Particles/ShipBullet2.tscn")

# Timers, fer-ho amb arrays?
var fire_rates := { 0 : 4.0, 1 : 2.0 }
var next_times_to_fire := { 0 : 0.0, 1 : 0.0}
var time_now := 0.0

var shoot_action_name := "shoot"
var zoom_action_name := "zoom"

func _ready() -> void:
	pass

func _process(delta : float) -> void:
	time_now += delta
	
	if not get_parent().is_player or not get_parent().state == 1:
		return
	
	# Passar també el jugador?
	if get_tree().has_network_peer():
		if not get_parent().is_player:
			return
		elif not get_parent().is_network_master():
			return
	
	if Input.is_action_pressed(shoot_action_name) and time_now >= next_times_to_fire[0]:
		next_times_to_fire[0] = time_now + 1.0 / fire_rates[0]
		var shoot_calcs = calc_shoot()
		if get_tree().has_network_peer():
			rpc("shoot", 0, shoot_calcs[0], shoot_calcs[1])
		else:
			shoot(0, shoot_calcs[0], shoot_calcs[1])
	
	if Input.is_action_pressed(zoom_action_name) and time_now >= next_times_to_fire[1]:
		next_times_to_fire[1] = time_now + 1.0 / fire_rates[1]
		var shoot_calcs = calc_shoot()
		if get_tree().has_network_peer():
			rpc("shoot", 1, shoot_calcs[0], shoot_calcs[1])
		else:
			shoot(1, shoot_calcs[0], shoot_calcs[1])

func calc_shoot(): # -> Array:
	# Camera
	var current_cam = ProjectSettings.get("ship_camera" + String(get_parent().number_of_player))
	var space_state = get_world().direct_space_state
	
	if current_cam != null:
		var viewport : Viewport
		# Millor preguntar si és el network_master per al splitscreen online (¿Ara és igual?)
		if get_tree().has_network_peer():
			viewport = get_node("/root/Main/Splitscreen")._renders[0].viewport
		else:
			viewport = get_node("/root/Main/Splitscreen")._renders[get_parent().number_of_player - 1].viewport
		camera_width_center = viewport.get_visible_rect().size.x / 2
		camera_height_center = viewport.get_visible_rect().size.y / 2
		
		shoot_origin = current_cam.project_ray_origin(Vector2(camera_width_center, camera_height_center))
		shoot_normal = shoot_origin + current_cam.project_ray_normal(Vector2(camera_width_center, camera_height_center)) * shoot_range
		
		var result = space_state.intersect_ray(shoot_origin, shoot_normal, [get_parent()])
		if result.empty():
			var ray_dir = current_cam.project_ray_normal(Vector2(camera_width_center, camera_height_center))
			shoot_target = shoot_origin + ray_dir * shoot_range
		else:
			shoot_target = result.position
		
		return [shoot_target, shoot_origin]

sync func shoot(bullet_type : int, shoot_target, shoot_origin) -> void:
	# Sound
	if bullet_type == 0:
		$Audio.play()
	elif bullet_type == 1:
		$Audio2.play()
	
	var bullet : KinematicBody
	if bullet_type == 0:
		bullet = bullet_scene.instance()
	elif bullet_type == 1:
		bullet = secondary_bullet_scene.instance()
	get_node("/root/Main").add_child(bullet)
	var shoot_from := global_transform.origin
	bullet.global_transform.origin = shoot_from
	bullet.direction = (shoot_target - shoot_origin).normalized() 
	bullet.add_collision_exception_with(get_parent())
