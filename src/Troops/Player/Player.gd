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

var online_id : int = 1

# temporal
var wait_a_fcking_moment := false

var current_csh_id := 0


func init(new_nickname, start_position, start_crouching, start_health, start_alive, start_in_a_vehicle, start_csh_id) -> void:
	if start_alive:
		$HealthSystem.health = start_health
		if start_in_a_vehicle:
			$HealthSystem.update_components(false)
		elif start_crouching:
			$Crouch.crouch()
	else:
		if get_tree().has_network_peer(): # cal comprovar-ho?
			$HealthSystem.rpc("die") 
		else:
			$HealthSystem.die()
	
	if start_csh_id != 0:
		for csh in get_tree().get_nodes_in_group("CapitalShips"):
			if csh.cap_ship_id == start_csh_id:
				get_parent().remove_child(self)
				csh.add_child(self)
				break
	
	translation = start_position
	nickname = new_nickname
	
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
			$TroopManager.m_team = Network.players[number_of_player - 1][online_id].team # què ve a compondre açò? per si vol canviar d'equi enmig de la partida?
	else:
		if Input.is_key_pressed(KEY_K):
			$HealthSystem.take_damage(INF)
	
	var camera_down_action := "camera_down" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_down
	var camera_up_action := "camera_up" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_up
	var camera_left_action := "camera_left" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_left
	var camera_right_action := "camera_right" if LocalMultiplayer.number_of_players == 1 else $InputManager.input_map.camera_right
	
	"""
	comprovació per evitar errors, puix que en el multijugador local el
	jugador que té el ratolí no té les accions nomenades i genera molts avisos
	vermells en el depurador
	"""
	if camera_right_action:
		joystick_movement = Vector2(Input.get_action_strength(camera_right_action) - Input.get_action_strength(camera_left_action), 
									Input.get_action_strength(camera_down_action) - Input.get_action_strength(camera_up_action))
	joystick_movement *= joystick_sensitivity
	
	# $PlayerMesh.moving = true if $StateMachine/Movement/Move.direction else false


func _physics_process(delta : float) -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			$StateMachine/Movement/Move.can_run = false if $CameraBase.zooming or $Crouch.crouching or $Weapons.attacking else true
			
			$StateMachine/Movement/Aim.aim(delta)
			$StateMachine/Movement/Move.walk(delta)
			
			rset_unreliable("slave_position", global_transform.origin)
			rset_unreliable("slave_rotation", rotation.y)
			
			update_network_info()
		else:
			global_transform.origin = slave_position
			rotation = Vector3(0, slave_rotation, 0)
	else:
		$StateMachine/Movement/Move.can_run = false if $CameraBase.zooming or $Crouch.crouching or $Weapons.attacking else true
		
		$StateMachine/Movement/Aim.aim(delta)
		$StateMachine/Movement/Move.walk(delta)


func update_network_info() -> void:
	if get_parent().is_in_group("CapitalShips"):
		current_csh_id = get_parent().cap_ship_id
	Network.update_info(online_id, translation, rotation.y, $Crouch.crouching,
	$HealthSystem.health, $TroopManager.is_alive, $Interaction.is_in_a_vehicle,
	current_csh_id, number_of_player)
