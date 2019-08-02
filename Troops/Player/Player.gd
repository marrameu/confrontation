extends KinematicBody
class_name Player

# Camera
var mouse_sensitivity := 0.0015
var joystick_sensitivity := 0.06

const CAMERA_X_ROT_MIN := -50
const CAMERA_X_ROT_MAX := 60

var camera_x_rot := 0.0

var camera_change := Vector2()
var mouse_movement := Vector2()
var joystick_movement := Vector2()

# Move
var velocity := Vector3()
var direction := Vector3()

# Walk
var can_run := true
var gravity := -9.8 * 4
const MAX_SPEED := 6.75
const MAX_RUNNING_SPEED := 10
const ACCEL := 2
const DEACCEL := 6

# Jump
var jump_height := 12
var has_contact := false

# Slope
const MAX_SLOPE_ANGLE := 35

# Respawn
var spawn_position := Vector3(0, 10, 0)

# Multiplayer
var number_of_player : int
var jump_action_name := ""
var run_action_name := ""

# Networking
puppet var slave_position : = Vector3()
puppet var slave_rotation : = 0.0
var nickname := "Noname"

func init(new_nickname, start_position, start_crounching, start_health, start_alive, start_in_a_vehicle) -> void:
	# Position and Nickname
	translation = start_position
	nickname = new_nickname
	
	# Start Alive
	if start_alive:
		$HealthSystem.health = start_health
		if start_in_a_vehicle:
			disable_components(false)
		elif start_crounching:
			$Crounch.crounch()
	else:
		if get_tree().has_network_peer():
			rpc("die") 
		else:
			die()
	
	#Audio
	if get_tree().has_network_peer():
		if not is_network_master():
			$Listener.clear_current()

func _ready() -> void:
	if LocalMultiplayer.number_of_players == 1:
		jump_action_name = "jump"
		run_action_name = "run"
	elif LocalMultiplayer.number_of_players > 1:
		jump_action_name = get_node("InputManager").input_map.jump
		run_action_name = get_node("InputManager").input_map.run
	
	mouse_sensitivity *= Settings.mouse_sensitivity
	joystick_sensitivity *= Settings.joystick_sensitivity

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			if Input.is_key_pressed(KEY_K):
				_on_HealthSystem_die()
		else:
			$TroopManager.m_team = Network.players[number_of_player - 1][int(name)].team
	else:
		if Input.is_key_pressed(KEY_K):
			_on_HealthSystem_die()
	
	if LocalMultiplayer.number_of_players == 1:
		joystick_movement = Vector2(Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left"), 
									Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up"))
		joystick_movement *= joystick_sensitivity
	else:
		if LocalMultiplayer.controller_of_each_player[number_of_player - 1] != -1:
			joystick_movement = Vector2(Input.get_action_strength($InputManager.input_map.camera_right) - Input.get_action_strength($InputManager.input_map.camera_left), 
										Input.get_action_strength($InputManager.input_map.camera_down) - Input.get_action_strength($InputManager.input_map.camera_up))
			joystick_movement *= joystick_sensitivity

func _physics_process(delta : float) -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			if $CameraBase.zooming or $Crounch.crounching:
				can_run = false
			else:
				can_run = true
			aim()
			walk(delta)
			
			rset_unreliable("slave_position", translation)
			rset_unreliable("slave_rotation", rotation.y)
			
			update_network_info()
		else:
			translation = slave_position
			rotation = Vector3(0, slave_rotation, 0)
	else:
		if $CameraBase.zooming or $Crounch.crounching:
			can_run = false
		else:
			can_run = true
		aim()
		walk(delta)

func walk(delta : float) -> void:
	# Reset player direction
	direction = Vector3() 
	
	# Check input and change the direction
	var aim := get_global_transform().basis
	if LocalMultiplayer.number_of_players == 1:
		direction += aim.x * (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
		direction += aim.z * (Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward"))
	else:
		direction += aim.x * (Input.get_action_strength($InputManager.input_map.move_right) - Input.get_action_strength($InputManager.input_map.move_left))
		direction += aim.z * (Input.get_action_strength($InputManager.input_map.move_backward) - Input.get_action_strength($InputManager.input_map.move_forward))
	
	direction.y = 0
	direction = direction.normalized()
	
	# Gravity and slopes
	if is_on_floor():
		has_contact = true
		var n = $Tail.get_collision_normal()
		var floor_angle := rad2deg(acos(n.dot(Vector3(0, 1, 0))))
		if floor_angle > MAX_SLOPE_ANGLE:
			velocity.y += gravity * delta
	else:
		if not $Tail.is_colliding():
			has_contact = false
		velocity.y += gravity * delta
	
	if has_contact and not is_on_floor():
		move_and_collide(Vector3(0, -1, 0))
	
	var temp_velocity := velocity
	temp_velocity.y = 0
	
	var speed
	if Input.is_action_pressed(run_action_name) and can_run:
		speed = MAX_RUNNING_SPEED
	else:
		speed = MAX_SPEED
	
	# Max velocity
	var target = direction * speed
	
	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = ACCEL
	else:
		acceleration = DEACCEL
	
	# Increase the velocity
	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)
	
	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z
	
	# Jump (Before moving)
	if Input.is_action_just_pressed(jump_action_name) and has_contact:
		velocity.y = jump_height
		has_contact = false
		if $Crounch.crounching:
			if get_tree().has_network_peer():
				$Crounch.rpc("get_up")
			else:
				$Crounch.get_up()
	
	# Move
	velocity = move_and_slide(velocity, Vector3(0, 1, 0), false, 4, deg2rad(MAX_SLOPE_ANGLE))

func aim() -> void:
	if LocalMultiplayer.number_of_players == 1 or $InputManager.number_of_device == -1:
		mouse_movement = Utilities.mouse_movement * mouse_sensitivity
	$CameraBase.input_movement = joystick_movement + mouse_movement
	camera_change += joystick_movement + mouse_movement
	if(camera_change.length() > 0):
		# Rotate camera [X]
		camera_x_rot = clamp(-$CameraBase.rotation.x + camera_change.y, deg2rad(CAMERA_X_ROT_MIN), deg2rad(CAMERA_X_ROT_MAX))
		$CameraBase.rotation.x = -camera_x_rot
		$CameraBase.orthonormalize()
		# Rotate player [Y]
		rotate_y(-camera_change.x)
		orthonormalize()
		# Reset camera input
		camera_change = Vector2()
		joystick_movement = Vector2()

func _on_HealthSystem_die() -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			($RespawnTimer as Timer).start()
	else:
		($RespawnTimer as Timer).start()
	
	if get_tree().has_network_peer():
		rpc("die")
	else:
		die()

func _on_RespawnTimer_timeout() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var selection_menu : SelectionMenu = get_node("/root/Main").selection_menus[number_of_player - 1]
	var spawn_menu = selection_menu.get_node("Container/SpawnMenu")
	spawn_menu.get_node("SpawnButton").hide()
	spawn_menu.show()
	
	# GRAB FOCUS
	# get_node("/root/Main/CommandPosts").get_child(0).buttons[number_of_player - 1].grab_focus()

sync func die() -> void:
	$HealthSystem.health = 0 # Para el HUD (temporal)
	$TroopManager.is_alive = false
	# Per a cambiar is_alive
	if get_tree().has_network_peer(): # Per al mode un jugador
		if is_network_master():
			update_network_info()
	if get_tree().has_network_peer():
		rpc("disable_components", true)
	else:
		disable_components(true)
	var scene_camera : Camera = ProjectSettings.get("scene_camera_" + String(number_of_player))
	if scene_camera:
		if get_tree().has_network_peer():
			if is_network_master():
				scene_camera.make_current()
		else:
			scene_camera.make_current()

sync func respawn() -> void:
	$TroopManager.is_alive = true
	var command_posts := []
	for command_post in get_node("/root/Main/CommandPosts").get_children():
		if command_post.m_team == $TroopManager.m_team:
			command_posts.push_back(command_post)
		if command_posts.size() < 1:
			# No hay más CP de tu equipo
			translation = Vector3(rand_range(-100, 100), 2, rand_range(-100, 100))
		else:
			translation = spawn_position
	rotation = Vector3()
	if get_tree().has_network_peer():
		rpc("enable_components", true)
	else:
		enable_components(true)
	var scene_camera : Camera = ProjectSettings.get("scene_camera_" + String(number_of_player))
	if scene_camera:
		if get_tree().has_network_peer():
			if is_network_master():
				scene_camera.clear_current()
		else:
			scene_camera.clear_current()
	$HealthSystem.health = $HealthSystem.max_health

sync func disable_components(var disable_interaction : bool) -> void:
	set_physics_process(false)
	set_process(false)
	if $Crounch.crounching:
		$Crounch.get_up()
	$Crounch.set_process(false)
	$CameraBase.set_process(false)
	if disable_interaction:
		$Interaction.set_process(false)
	for weapon in $Weapons.get_children():
		weapon.get_node("Timer").stop()
		weapon.set_process(false)
		#HUD
		var weapon_hud = weapon.get_node("HUD")
		if weapon_hud:
			for child in weapon_hud.get_children():
				if child.has_method("hide"):
					child.hide()
	for child in get_children():
		if child.has_method("hide"):
			child.hide()
	$CollisionShape.disabled = true
	if get_tree().has_network_peer():
		if is_network_master():
			$CameraBase/Camera.clear_current()
	else:
		$CameraBase/Camera.clear_current()

sync func enable_components(var enable_interaction : bool) -> void:
	set_physics_process(true)
	set_process(true)
	$Crounch.set_process(true)
	$CameraBase.set_process(true)
	if enable_interaction:
		$Interaction.set_process(true)
	for weapon in $Weapons.get_children():
		weapon.set_process(true)
		#HUD
		var weapon_hud = weapon.get_node("HUD")
		if weapon_hud:
			for child in weapon_hud.get_children():
				if child.has_method("show"):
					child.show()
	for child in get_children():
		if child.has_method("show"):
			child.show()
	$CollisionShape.disabled = false
	if get_tree().has_network_peer():
		if is_network_master():
			$CameraBase/Camera.make_current()
	else:
		$CameraBase/Camera.make_current()

func update_network_info():
	Network.update_info(int(name), translation, rotation.y, $Crounch.crounching,
	$HealthSystem.health, $TroopManager.is_alive, $Interaction.is_in_a_vehicle, number_of_player)
