extends Spatial

var cam_pos_x : float
onready var init_cam_pos_x : float = $Camera.translation.x
onready var tween : Tween = $Tween

var zooming := false
var init_mouse_sensitivity : float
var init_joystick_sensitivity : float

var original_cam_rot := Vector2()
var input_movement := Vector2()
var shake_density := Vector2()

var shooting := false
var recoiling := false
var multiplier := 1.0
var recoil_density := Vector2()

# Multiplayer
var action_name := ""

func _ready() -> void:
	init_joystick_sensitivity = get_parent().joystick_sensitivity * Settings.joystick_sensitivity
	init_mouse_sensitivity = get_parent().mouse_sensitivity * Settings.mouse_sensitivity
	cam_pos_x = init_cam_pos_x
	$Camera.fov = Settings.fov

func _process(delta : float) -> void:
	if action_name == "":
		if LocalMultiplayer.number_of_players == 1:
			action_name = "zoom"
		elif LocalMultiplayer.number_of_players > 1:
			action_name = get_node("../InputManager").input_map.zoom
	
	# Change View Side
	if LocalMultiplayer.number_of_players == 1:
		if Input.is_action_just_pressed("change_view"):
			move_camera()
	elif LocalMultiplayer.number_of_players > 1:
		if Input.is_action_just_pressed(get_node("../InputManager").input_map.change_view):
			move_camera()
	
	$Camera.translation.x = cam_pos_x

func _physics_process(delta : float) -> void:
	if Input.is_action_pressed(action_name):
		$Camera.fov = lerp($Camera.fov, 35, .15)
		get_parent().mouse_sensitivity = init_mouse_sensitivity / 2
		get_parent().joystick_sensitivity = init_joystick_sensitivity / 3
		zooming = true
	elif not Input.is_action_pressed(action_name):
		$Camera.fov = lerp($Camera.fov, Settings.fov, .15)
		get_parent().mouse_sensitivity = init_mouse_sensitivity
		get_parent().joystick_sensitivity = init_joystick_sensitivity
		zooming = false
	
	# Shake
	if input_movement.length() > 0:
		recoiling = false
		shooting = false
	
	recoil_density.x = original_cam_rot.x - rotation.x
	
	if shooting:
		var to = rotation.x + shake_density.x
		rotation.x = clamp(lerp(rotation.x, to, 0.05), deg2rad(get_parent().CAMERA_X_ROT_MIN - 10), deg2rad(get_parent().CAMERA_X_ROT_MAX - 10))
		shake_density.x = lerp(shake_density.x, 0, 0.15)
		get_parent().rotation.y = lerp(get_parent().rotation.y, get_parent().rotation.y + shake_density.y, 0.15)
		original_cam_rot.y = get_parent().rotation.y - shake_density.y
		shake_density.y = lerp(shake_density.y, 0, 0.15)
	
	if recoiling and not shooting:
		var to = rotation.x + recoil_density.x
		rotation.x = lerp(rotation.x, to, 0.15)
		get_parent().rotation.y = lerp(get_parent().rotation.y, get_parent().rotation.y - recoil_density.y, 0.15)
		recoil_density.y = lerp(recoil_density.y, 0, 0.15)
		recoil_density.x = lerp(recoil_density.x, 0, 0.15)

func shake_camera() -> void:
	if not shooting:
		shooting = true
		original_cam_rot.x = rotation.x
	if get_parent().get_node("Crounch").crounching:
		multiplier = 0.15
	elif zooming:
		multiplier = 0.5
	else:
		multiplier = 1.0
	shake_density.x = 0.025 * multiplier
	if randf() > 0.5:
		shake_density.y = rand_range(0.002 * multiplier, 0.005 * multiplier)
	else:
		shake_density.y = rand_range(-0.005 * multiplier, -0.002 * multiplier)
	if shake_density.y + recoil_density.y > 0.01 or shake_density.y + recoil_density.y < -0.01:
		shake_density.y = 0
	recoil_density.y += shake_density.y
	recoiling = true

func stop_shake_camera() -> void:
	shooting = false

func move_camera() -> void:
	if cam_pos_x > 0:
		tween.interpolate_property(self, "cam_pos_x", cam_pos_x, -init_cam_pos_x, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	else:
		tween.interpolate_property(self, "cam_pos_x", cam_pos_x, init_cam_pos_x, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
