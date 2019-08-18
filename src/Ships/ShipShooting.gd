extends Node

var shoot_range := 1500

# Bullets
const bullet_scene : PackedScene = preload("res://src/Bullets/Ships/ShipBullet.tscn")
const secondary_bullet_scene : PackedScene = preload("res://src/Bullets/Ships/ShipBullet2.tscn")

# Timers, fer-ho amb arrays?
var fire_rates := { 0 : 4.0, 1 : 2.0 }
var next_times_to_fire := { 0 : 0.0, 1 : 0.0}
var time_now := 0.0

var shoot_action := "shoot"
var zoom_action := "zoom"

func _ready() -> void:
	pass

func _process(delta : float) -> void:
	time_now += delta
	
	if not get_parent().is_player or not get_parent().state == get_parent().State.FLYING:
		return
	
	# Passar també el jugador?
	if get_tree().has_network_peer():
		if not get_parent().is_player:
			return
		elif not get_parent().is_network_master():
			return
	
	if Input.is_action_pressed(shoot_action) and time_now >= next_times_to_fire[0]:
		next_times_to_fire[0] = time_now + 1.0 / fire_rates[0]
		if get_tree().has_network_peer():
			rpc("shoot", 0, shoot_target())
		else:
			shoot(0, shoot_target())
	
	if Input.is_action_pressed(zoom_action) and time_now >= next_times_to_fire[1]:
		next_times_to_fire[1] = time_now + 1.0 / fire_rates[1]
		if get_tree().has_network_peer():
			rpc("shoot", 1, shoot_target())
		else:
			shoot(1, shoot_target())

func shoot_target() -> Vector3:
	# Camera
	var current_cam : Camera = get_node("/root/Main").players_cameras[get_parent().number_of_player - 1].ship_camera
	var space_state = get_parent().get_world().direct_space_state
	
	var camera_width_center := 0.0
	var camera_height_center := 0.0
	var shoot_origin := Vector3()
	var shoot_normal := Vector3()
	var shoot_target := Vector3()
	
	if current_cam:
		var viewport : Viewport
		if get_tree().has_network_peer():
			viewport = get_node("/root/Main/Splitscreen")._renders[0].viewport
		else:
			viewport = get_node("/root/Main/Splitscreen")._renders[get_parent().number_of_player - 1].viewport
		camera_width_center = viewport.get_visible_rect().size.x / 2
		camera_height_center = viewport.get_visible_rect().size.y / 2
		
		# TEST
		var cursor_pos = get_node("../PlayerHUD/Center/CursorPivot/Cursor").rect_position # .clamped(350)
		if LocalMultiplayer.number_of_players > 1:
			cursor_pos /= 2
		camera_width_center += cursor_pos.x
		camera_height_center += cursor_pos.y
		
		shoot_origin = current_cam.project_ray_origin(Vector2(camera_width_center, camera_height_center))
		shoot_normal = shoot_origin + current_cam.project_ray_normal(Vector2(camera_width_center, camera_height_center)) * shoot_range
		
		var result = space_state.intersect_ray(shoot_origin, shoot_normal, [get_parent()])
		if result.empty():
			var ray_dir = current_cam.project_ray_normal(Vector2(camera_width_center, camera_height_center))
			shoot_target = shoot_origin + ray_dir * shoot_range
		else:
			shoot_target = result.position
		
	return shoot_target

sync func shoot(bullet_type : int, shoot_target) -> void:
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
	var shoot_from : Vector3 = get_parent().global_transform.origin # Canons
	bullet.global_transform.origin = shoot_from
	bullet.direction = (shoot_target - shoot_from).normalized() 
	bullet.ship = get_parent()
