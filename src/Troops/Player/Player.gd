extends KinematicBody
class_name Player

# Camera
var mouse_sensitivity := 0.0015
var joystick_sensitivity := 0.06 # * 0.8 a 0.7 quan arregli els joysticks

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
	translation = start_position
	nickname = new_nickname
	
	if start_alive:
		$HealthSystem.health = start_health
		if start_in_a_vehicle:
			$HealthSystem.disable_components(false)
		elif start_crouching:
			$Crouch.crouch()
	else:
		if get_tree().has_network_peer():
			$HealthSystem.rpc("die") 
		else:
			$HealthSystem.die()
	
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
				$HealthSystem.take_damage(INF)
		else:
			$TroopManager.m_team = Network.players[number_of_player - 1][int(name)].team
	else:
		if Input.is_key_pressed(KEY_K):
			$HealthSystem.take_damage(INF)
	
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


func update_network_info() -> void:
	Network.update_info(int(name), translation, rotation.y, $Crouch.crouching,
	$HealthSystem.health, $TroopManager.is_alive, $Interaction.is_in_a_vehicle, number_of_player)
