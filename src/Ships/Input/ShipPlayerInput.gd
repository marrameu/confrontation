extends Node

onready var physics : ShipPhysics = get_node("../../Physics") # ¿?
onready var ship : Ship = get_node("../../") # ¿?

var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var strafe := 0.0
var throttle := 0.0
export(float, -1, 1) var min_throttle := 0.3

# How quickly reacts to input
# Move Towards 0.5
const THROTTLE_SPEED := 2.5
const ROLL_SPEED := 2.5

var mouse_input := Vector2()
var input_device : int

var move_right_action := "move_right"
var move_left_action := "move_left"
var move_forward_action := "move_forward"
var move_backward_action := "move_backward"

var camera_down_action := "camera_down"
var camera_up_action := "camera_up"
var camera_left_action := "camera_left"
var camera_right_action := "camera_right"


func _ready() -> void:
	pass


func _process(delta : float) -> void:
	roll = clamp(lerp(roll, (Input.get_action_strength(move_right_action) - Input.get_action_strength(move_left_action)), delta * ROLL_SPEED), -1, 1)
	
	update_yaw_and_ptich()
	update_throttle(move_forward_action, move_backward_action, delta)


func update_yaw_and_ptich() -> void:
	mouse_input.x = get_node("../../PlayerHUD").input.x
	mouse_input.y = -get_node("../../PlayerHUD").input.y
	
	pitch = mouse_input.y if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or input_device == -1 else Input.get_action_strength(camera_down_action) - Input.get_action_strength(camera_up_action)
	yaw = -mouse_input.x if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or input_device == -1 else Input.get_action_strength(camera_left_action) - Input.get_action_strength(camera_right_action)


func update_throttle(increase_action : String, decrease_action : String, delta : float) -> void:
	var target := throttle
	target = clamp(Input.get_action_strength(increase_action) - Input.get_action_strength(decrease_action), min_throttle, 1)
	# Change to move_towards
	throttle = clamp(lerp(throttle, target, delta * THROTTLE_SPEED), -1, 1)
