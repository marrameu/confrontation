extends Camera

var target : Position3D = null
var starter_target_position := Vector3()
var rotate_speed := 90.0

# var move_speed_test := 90.0
# var rotate_speed_test := 80.0

var horizontal_turn_move := 6.0
var vertical_turn_up_move := 6.0
var vertical_turn_down_move := 3.0

var zooming := false

# Input
var input_device := 0
var zoom_ship_action := "zoom_ship"
var look_behind_action := "look_behind"
var camera_right_action := "camera_right"
var camera_left_action := "camera_left"
var camera_up_action := "camera_up"
var camera_down_action := "camera_down"

func init(new_target : Position3D, player : int) -> void:
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	
	get_parent().remove_child(self)
	current_scene.get_node("Splitscreen").get_player(player - 1).viewport.add_child(self)
	
	target = new_target
	translation = target.global_transform.origin
	rotation = target.global_transform.basis.get_euler()
	starter_target_position = target.translation
	
	make_current()

func _physics_process(delta : float) -> void:
	if not target:
		fov = 40 # Si al final trec l'efecte, canviar el nombre a 70
		return
	
	if Input.is_action_just_pressed(zoom_ship_action) and target.get_parent().state == target.get_parent().State.FLYING:
		zooming = !zooming
	
	if zooming and target.get_parent().state == target.get_parent().State.FLYING:
		fov = lerp(fov, 40, .15)
	else:
		zooming = false
		fov = lerp(fov, 70, .15)
	
	move_camera(delta)

func move_camera(delta : float) -> void:
	if not target:
		return
	
	if not Input.is_action_pressed(look_behind_action):
		translation = target.global_transform.origin
	else:
		translation = target.get_parent().global_transform.origin + target.get_parent().global_transform.basis.xform(Vector3(target.translation.x, target.translation.y, -target.translation.z))
	
	if Input.is_action_pressed(look_behind_action):
		target.rotation_degrees = Vector3()
		rotation = target.global_transform.basis.get_euler()
	else:
		target.rotation_degrees = Vector3(0, 180, 0)
		rotation = target.global_transform.basis.get_euler()
	
	global_transform.basis = Quat(global_transform.basis).slerp(Quat(target.get_global_transform().basis), rotate_speed * delta)
	update_target(delta)
	
	# global_transform.origin = global_transform.origin.slerp(target.global_transform.origin, move_speed_test * delta)
	# var a : Vector3 = target.global_transform.basis.get_euler()
	# Cambiar para hacer compatible con el look behind
	# rotation_degrees = rotation_degrees.slerp(Vector3(rad2deg(a.x), rad2deg(a.y), rad2deg(a.z)), rotate_speed_test * delta)

func update_target(delta : float):
	# Mirar si la nau esta en moviment, si ho està, resetejar la posició del target i no fer res més
	if target.get_parent().state != target.get_parent().State.FLYING:
		target.translation = target.translation.linear_interpolate(Vector3(0, 6, -30), delta)
		horizontal_lean(target.get_node("../ShipMesh"), 0.0)
		return
	
	var mouse_position : Vector2 = Utilities.mouse_position
	var mouse_screen_x : float
	var mouse_screen_y : float
	
	mouse_screen_x = target.get_node("../PlayerHUD").input.x if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or input_device == -1 else Input.get_action_strength(camera_right_action) - Input.get_action_strength(camera_left_action)
	mouse_screen_y = target.get_node("../PlayerHUD").input.y if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or input_device == -1 else Input.get_action_strength(camera_up_action) - Input.get_action_strength(camera_down_action)
	var viewport_size = get_tree().root.get_visible_rect().size
	
	mouse_screen_x = clamp(mouse_screen_x, -1, 1)
	mouse_screen_y = clamp(mouse_screen_y, -1, 1)
	
	horizontal_lean(target.get_node("../ShipMesh"), mouse_screen_x)
	
	var horizontal := horizontal_turn_move * mouse_screen_x
	var vertical := 0.0
	if mouse_screen_y < 0.0:
		vertical = vertical_turn_up_move * mouse_screen_y
	else:
		vertical = vertical_turn_down_move * mouse_screen_y
	
	var desired_position = starter_target_position + Vector3(-horizontal, vertical, 0.0)
	target.translation = target.translation.linear_interpolate(desired_position, delta)

func horizontal_lean(target : Spatial, x_input : float, lean_limit : float = 45 , time : float = 0.03) -> void:
	var target_rotation : Vector3 = target.rotation_degrees
	target.rotation_degrees = Vector3(target_rotation.x, target_rotation.y, lerp(target_rotation.z, x_input * lean_limit, time))
