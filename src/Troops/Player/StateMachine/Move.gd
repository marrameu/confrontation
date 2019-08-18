extends "res://src/Troops/Player/StateMachine/State.gd"

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
var jump_height := 14
var has_contact := false

# Slope
const MAX_SLOPE_ANGLE := 35

func _ready():
	pass

func walk(delta : float) -> void:
	# Reset player direction
	var player : KinematicBody = get_node("../../..") # : Player
	direction = Vector3()
	
	var input_map : Dictionary = player.get_node("InputManager").input_map
	var move_right_action := "move_right" if LocalMultiplayer.number_of_players == 1 else input_map.move_right
	var move_left_action := "move_left" if LocalMultiplayer.number_of_players == 1 else input_map.move_left
	var move_forward_action := "move_forward" if LocalMultiplayer.number_of_players == 1 else input_map.move_forward
	var move_backward_action := "move_backward" if LocalMultiplayer.number_of_players == 1 else input_map.move_backward
	
	# Check input and change the direction
	var aim : Basis = player.get_global_transform().basis
	direction += aim.x * (Input.get_action_strength(move_left_action) - Input.get_action_strength(move_right_action))
	direction += aim.z * (Input.get_action_strength(move_forward_action) - Input.get_action_strength(move_backward_action))
	
	direction.y = 0
	direction = direction.normalized()
	
	# Gravity and slopes
	if player.is_on_floor():
		has_contact = true
		var n = player.get_node("Tail").get_collision_normal()
		var floor_angle := rad2deg(acos(n.dot(Vector3(0, 1, 0))))
		if floor_angle > MAX_SLOPE_ANGLE:
			velocity.y += gravity * delta
	else:
		if not player.get_node("Tail").is_colliding():
			has_contact = false
		velocity.y += gravity * delta
	
	if has_contact and not player.is_on_floor():
		player.move_and_collide(Vector3(0, -1, 0))
	
	var temp_velocity : Vector3 = velocity
	temp_velocity.y = 0
	
	var speed : float
	if Input.is_action_pressed(player.run_action) and can_run:
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
	if Input.is_action_just_pressed(player.jump_action) and has_contact:
		velocity.y = jump_height
		has_contact = false
		if player.get_node("Crouch").crouching:
			if get_tree().has_network_peer():
				player.get_node("Crouch").rpc("get_up")
			else:
				player.get_node("Crouch").get_up()
	
	# Move
	velocity = player.move_and_slide(velocity, Vector3(0, 1, 0), false, 4, deg2rad(MAX_SLOPE_ANGLE))
