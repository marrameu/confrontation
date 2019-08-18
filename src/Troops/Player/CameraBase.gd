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
var zoom_action := ""
var change_view_action := ""

func _ready() -> void:
	init_joystick_sensitivity = get_parent().joystick_sensitivity * Settings.joystick_sensitivity
	init_mouse_sensitivity = get_parent().mouse_sensitivity * Settings.mouse_sensitivity
	cam_pos_x = init_cam_pos_x
	$Camera.fov = Settings.fov

func _process(delta : float) -> void:
	if zoom_action == "":
		zoom_action = "zoom" if LocalMultiplayer.number_of_players == 1 else get_node("../InputManager").input_map.zoom
	if change_view_action == "":
		change_view_action = "change_view" if LocalMultiplayer.number_of_players == 1 else get_node("../InputManager").input_map.change_view
	
	# Change View Side
	if Input.is_action_just_pressed(change_view_action):
		move_camera()
	
	$Camera.translation.x = cam_pos_x

func _physics_process(delta : float) -> void:
	zooming = Input.is_action_pressed(zoom_action)
	
	$Camera.fov = lerp($Camera.fov, Settings.fov / 2.0, .15) if zooming else lerp($Camera.fov, Settings.fov, .15)
	get_parent().mouse_sensitivity = init_mouse_sensitivity / 2 if zooming else init_mouse_sensitivity
	get_parent().joystick_sensitivity = init_joystick_sensitivity / 3 if zooming else init_joystick_sensitivity
	
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

func shake_camera(shake_force := Vector2(1, 1)) -> void:
	# Els eixos estan invertits per a la rotació
	# En un futur moure la càmara enrere
	if not shooting:
		shooting = true
		original_cam_rot.x = rotation.x
	if get_parent().get_node("Crouch").crouching:
		multiplier = 0.15
	elif zooming:
		multiplier = 0.5
	else:
		multiplier = 1.0
	shake_density.x = 0.025 * multiplier * shake_force.x
	if randf() > 0.5:
		shake_density.y = rand_range(0.006 * multiplier * shake_force.y, 0.01 * multiplier * shake_force.y)
	else:
		shake_density.y = rand_range(-0.01 * multiplier * shake_force.y, -0.006 * multiplier * shake_force.y)
	if shake_density.y + recoil_density.y > (0.02 * shake_force.y * multiplier) or shake_density.y + recoil_density.y < (-0.02 * shake_force.y * multiplier):
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
