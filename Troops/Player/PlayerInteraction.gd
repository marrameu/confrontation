extends Node

# Shooting
var ray_range := 15
var camera_width_center := 0.0
var camera_height_center := 0.0
var ray_origin := Vector3()
var ray_normal := Vector3()

# Cameras
var ship_camera : Camera
var current_camera : Camera

# State
var is_in_a_vehicle := false
var current_vehicle : Spatial

# Multiplayer
var action_name := ""

func _ready() -> void:
	current_camera = get_node("../CameraBase/Camera")
	ship_camera = get_node("../CameraBase/ShipCamera")

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not is_network_master():
			return
	
	if action_name == "":
		if LocalMultiplayer.number_of_players == 1:
			action_name = "interact"
		elif LocalMultiplayer.number_of_players > 1:
			action_name = get_node("../InputManager").input_map.interact
	
	if not is_in_a_vehicle:
		if current_camera != null and Input.is_action_just_pressed(action_name):
			var viewport = get_node("/root/Main/Splitscreen")._renders[get_node("..").number_of_player - 1].viewport
			camera_width_center = viewport.get_visible_rect().size.x / 2
			camera_height_center = viewport.get_visible_rect().size.y / 2
			
			ray_origin = current_camera.project_ray_origin(Vector2(camera_width_center, camera_height_center))
			ray_normal = ray_origin + current_camera.project_ray_normal(Vector2(camera_width_center, camera_height_center)) * ray_range
			
			var space_state = current_camera.get_world().direct_space_state
			var result = space_state.intersect_ray(ray_origin, ray_normal, [])
			if result:
				if result.collider.is_in_group("Vehicles"):
					# Timer
					result.collider.get_node("InterpolatedCamera").current = true
					get_parent().get_node("CameraBase/Camera").current = false
				elif result.collider.is_in_group("Ships"):
					if not result.collider.is_player:
						enter_ship(result)
	else:
		if Input.is_action_just_pressed(action_name) and current_vehicle.state == 0:
			exit_ship()

func enter_ship(result):
	if get_tree().has_network_peer():
		rpc("change_ship_player", result.collider.get_path(), true, get_parent().name)
		get_parent().rpc("disable_components", false)
	else:
		change_ship_player(result.collider.get_path(), true, get_parent().name)
		get_parent().disable_components(false)
	
	result.collider.get_node("PlayerHUD/ShipUI/Control/Cursor").rect_position = Vector2(-0.5, -0.5)
	result.collider.number_of_player = get_parent().number_of_player
	ship_camera.init(result.collider.get_node("CameraPosition"), get_parent().number_of_player)
	is_in_a_vehicle = true
	if get_tree().has_network_peer():
		get_parent().update_network_info()

func exit_ship() -> void:
	ship_camera.get_parent().remove_child(ship_camera)
	get_node("../CameraBase").add_child(ship_camera)
	ship_camera.translation = Vector3()
	ship_camera.rotation = Vector3()
	ship_camera.target = null
	
	if get_tree().has_network_peer():
		rpc("change_ship_player", current_vehicle.get_path(), false, "")
		get_parent().rpc("enable_components", false)
		
	else:
		change_ship_player(current_vehicle.get_path(), false, "")
		get_parent().enable_components(false)
	
	current_vehicle.number_of_player = 0
	current_vehicle.set_linear_velocity(Vector3.ZERO)
	current_vehicle.get_node("CameraPosition").translation = Vector3(0, 6, -30) # Change when adding slerp or other ships
	get_parent().translation = current_vehicle.translation
	is_in_a_vehicle = false
	current_vehicle = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if get_tree().has_network_peer():
		get_parent().update_network_info()

sync func change_ship_player(ship_path : String, status : bool, name : String) -> void:
	current_vehicle = get_node(NodePath(ship_path))
	get_node(NodePath(ship_path)).is_player = status
	get_node(NodePath(ship_path)).player_name = name
