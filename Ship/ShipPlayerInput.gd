extends Node

onready var physics : ShipPhysics = get_node("../../Physics") # ¿?
onready var ship : Ship = get_node("../../") # ¿?

var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var strafe := 0.0
var throttle := 0.0
export(float, 0, 1) var min_throttle := 0.3

# How quickly reacts to input
const THROTTLE_SPEED := 2.5 # Move Towards 0.5
const STRAFE_SPEED := 2.5

var mouse_input := Vector2()
var input_device : int

var move_right_action_name := "move_right"
var move_left_action_name := "move_left"
var move_forward_action_name := "move_forward"
var move_backward_action_name := "move_backward"

var camera_down_action_name := "camera_down"
var camera_up_action_name := "camera_up"
var camera_left_action_name := "camera_left"
var camera_right_action_name := "camera_right"

func _ready() -> void:
	pass

func _process(delta : float) -> void:
	roll = lerp(roll, (Input.get_action_strength(move_right_action_name) - Input.get_action_strength(move_left_action_name)) * 5, delta * 8)
	strafe = lerp(strafe, 0, delta * STRAFE_SPEED) 
	
	update_yaw_and_ptich()
	update_throttle(move_forward_action_name, move_backward_action_name, delta)

func update_yaw_and_ptich() -> void:
	mouse_input.x = get_node("../../PlayerHUD/ShipUI").input.x
	mouse_input.y = -get_node("../../PlayerHUD/ShipUI").input.y
	
	if LocalMultiplayer.number_of_players == 1:
		if not Settings.controller_input:
			pitch = mouse_input.y
			yaw = -mouse_input.x
		else:
			pitch = Input.get_action_strength(camera_down_action_name) - Input.get_action_strength(camera_up_action_name)
			yaw = Input.get_action_strength(camera_left_action_name) - Input.get_action_strength(camera_right_action_name)
	else:
		if input_device == -1:
			pitch = mouse_input.y
			yaw = -mouse_input.x
		else:
			pitch = Input.get_action_strength(camera_down_action_name) - Input.get_action_strength(camera_up_action_name)
			yaw = Input.get_action_strength(camera_left_action_name) - Input.get_action_strength(camera_right_action_name)

func update_throttle(increase_action : String, decrease_action : String, delta : float) -> void:
	var target := throttle
	target = clamp(Input.get_action_strength(increase_action) - Input.get_action_strength(decrease_action), min_throttle, 1)
	# Change to move_towards
	throttle = lerp(throttle, target, delta * THROTTLE_SPEED)
