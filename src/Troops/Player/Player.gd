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

# Respawn
var spawn_position := Vector3(0, 10, 0)

# Multiplayer
var number_of_player : int
var jump_action := ""
var run_action := ""

# Networking
puppet var slave_position : = Vector3()
puppet var slave_rotation : = 0.0
var nickname := "Noname"


func init(new_nickname, start_position, start_crouching, start_health, start_alive, start_in_a_vehicle) -> void:
	# Position and Nickname
	translation = start_position
	nickname = new_nickname
	
	# Start Alive
	if start_alive:
		$HealthSystem.health = start_health
		if start_in_a_vehicle:
			disable_components(false)
		elif start_crouching:
			$Crouch.crouch()
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
	jump_action = "jump" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.jump
	run_action = "run" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.run
	
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
	
	var camera_down_action := "camera_down" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_down
	var camera_up_action := "camera_up" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_up
	var camera_left_action := "camera_left" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_left
	var camera_right_action := "camera_right" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_right
	
	joystick_movement = Vector2(Input.get_action_strength(camera_right_action) - Input.get_action_strength(camera_left_action), 
								Input.get_action_strength(camera_down_action) - Input.get_action_strength(camera_up_action))
	joystick_movement *= joystick_sensitivity
	
	# $PlayerMesh.moving = true if $StateMachine/Movement/Move.direction else false


func _physics_process(delta : float) -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			$StateMachine/Movement/Move.can_run = false if $CameraBase.zooming or $Crouch.crouching or $Weapons.attacking else true
			
			$StateMachine/Movement/Aim.aim()
			$StateMachine/Movement/Move.walk(delta)
			
			rset_unreliable("slave_position", translation)
			rset_unreliable("slave_rotation", rotation.y)
			
			update_network_info()
		else:
			translation = slave_position
			rotation = Vector3(0, slave_rotation, 0)
	else:
		$StateMachine/Movement/Move.can_run = false if $CameraBase.zooming or $Crouch.crouching or $Weapons.attacking else true
		
		$StateMachine/Movement/Aim.aim()
		$StateMachine/Movement/Move.walk(delta)

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
	# get_node("/root/Main/CommandPosts").get_child(0).buttons[number_of_player - 1].grab_focus()


sync func die() -> void:
	$HealthSystem.health = 0 # Para el HUD (temporal)
	$TroopManager.is_alive = false
	
	if get_tree().has_network_peer(): # Per al mode un jugador
		if is_network_master():
			update_network_info()
	if get_tree().has_network_peer():
		rpc("disable_components", true)
	else:
		disable_components(true)
	var scene_camera : Camera = get_node("/root/Main").players_cameras[number_of_player - 1].scene_camera
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
	var scene_camera : Camera = get_node("/root/Main").players_cameras[number_of_player - 1].scene_camera
	if scene_camera:
		if get_tree().has_network_peer():
			if is_network_master():
				scene_camera.clear_current()
		else:
			scene_camera.clear_current()
	$HealthSystem.heal($HealthSystem.MAX_HEALTH)


sync func disable_components(var disable_interaction : bool) -> void:
	set_physics_process(false)
	set_process(false)
	$StateMachine/Movement/Move.velocity = Vector3()
	if $Crouch.crouching:
		$Crouch.get_up()
	$Crouch.set_process(false)
	$CameraBase.set_process(false)
	if disable_interaction:
		$Interaction.set_process(false)
	for weapon in $Weapons.get_children():
		weapon.shooting = false
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
			$Listener.clear_current()
	else:
		$CameraBase/Camera.clear_current()
		$Listener.clear_current()


sync func enable_components(var enable_interaction : bool) -> void:
	set_physics_process(true)
	set_process(true)
	$Crouch.set_process(true)
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
			$Listener.make_current()
	else:
		$CameraBase/Camera.make_current()
		$Listener.make_current()


func update_network_info() -> void:
	Network.update_info(int(name), translation, rotation.y, $Crouch.crouching,
	$HealthSystem.health, $TroopManager.is_alive, $Interaction.is_in_a_vehicle, number_of_player)
