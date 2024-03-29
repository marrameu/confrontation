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
var action := ""

func _ready() -> void:
	current_camera = get_node("../CameraBase/Camera")
	ship_camera = get_node("../CameraBase/ShipCamera")

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not is_network_master():
			return
	
	if action == "":
		action = "interact" if LocalMultiplayer.number_of_players == 1 else get_node("../InputManager").input_map.interact
	
	if not is_in_a_vehicle:
		if current_camera and Input.is_action_just_pressed(action):
			var viewport = get_node("/root/Main/Splitscreen").get_player(get_node("..").number_of_player - 1).viewport
			camera_width_center = viewport.get_visible_rect().size.x / 2
			camera_height_center = viewport.get_visible_rect().size.y / 2
			
			ray_origin = current_camera.project_ray_origin(Vector2(camera_width_center, camera_height_center))
			ray_normal = ray_origin + current_camera.project_ray_normal(Vector2(camera_width_center, camera_height_center)) * ray_range
			
			var space_state = current_camera.get_world().direct_space_state
			var result = space_state.intersect_ray(ray_origin, ray_normal, [])
			if result:
				if result.collider.is_in_group("Vehicles"):
					# Timer
					# result.collider.get_node("InterpolatedCamera").make_current()
					# get_parent().get_node("CameraBase/Camera").clear_current()
					pass # això ja no anirià
				elif result.collider.is_in_group("Ships"):
					if not result.collider.is_player:
						enter_ship(result)
	else:
		if Input.is_action_just_pressed(action) and current_vehicle.state == current_vehicle.State.LANDED:
			exit_ship()


func enter_ship(result):
	if get_tree().has_network_peer():
		rpc("change_ship_player", result.collider.get_path(), true, get_parent().online_id)
		get_node("../HealthSystem").rpc("update_components", false, false)
	else:
		change_ship_player(result.collider.get_path(), true, get_parent().online_id)
		get_node("../HealthSystem").update_components(false, false)
	
	result.collider.get_node("PlayerHUD/Center/CursorPivot/Cursor").rect_position = Vector2()
	result.collider.number_of_player = get_parent().number_of_player
	ship_camera.init(result.collider.get_node("CameraPosition"), get_parent().number_of_player)
	if get_tree().has_network_peer():
		get_parent().update_network_info()


func exit_ship() -> void:
	ship_camera.get_parent().remove_child(ship_camera)
	get_node("../CameraBase").add_child(ship_camera)
	ship_camera.translation = Vector3()
	ship_camera.rotation = Vector3()
	ship_camera.target = null
	
	current_vehicle.number_of_player = 0
	current_vehicle.set_linear_velocity(Vector3())
	current_vehicle.get_node("CameraPosition").translation = Vector3(0, 6, -30) # Change when adding slerp or other ships
	get_parent().global_transform.origin = current_vehicle.global_transform.origin
	
	if get_tree().has_network_peer():
		rpc("change_ship_player", current_vehicle.get_path(), false, 0)
		get_node("../HealthSystem").rpc("update_components", true, false)
	else:
		change_ship_player(current_vehicle.get_path(), false, 0)
		get_node("../HealthSystem").update_components(true, false)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if get_tree().has_network_peer():
		get_parent().update_network_info()


sync func change_ship_player(ship_path : NodePath, status : bool, id : int) -> void:
	is_in_a_vehicle = status
	if status == true:
		current_vehicle = get_node(ship_path)
	else:
		current_vehicle = null
	
	if get_node(ship_path):
		get_node(ship_path).is_player = status
		get_node(ship_path).player_id = id
