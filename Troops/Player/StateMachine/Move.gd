extends "res://Troops/Player/StateMachine/State.gd"

func _ready():
	pass

func walk(delta : float) -> void:
	# Reset player direction
	var player : KinematicBody = get_node("../../..") # : Player
	var direction := Vector3() 
	
	var input_map : Dictionary = player.get_node("InputManager").input_map
	var move_right_action := "move_right" if LocalMultiplayer.number_of_players == 1 else input_map.move_right
	var move_left_action := "move_left" if LocalMultiplayer.number_of_players == 1 else input_map.move_left
	var move_forward_action := "move_forward" if LocalMultiplayer.number_of_players == 1 else input_map.move_forward
	var move_backward_action := "move_backward" if LocalMultiplayer.number_of_players == 1 else input_map.move_backward
	
	# Check input and change the direction
	var aim : Basis = player.get_global_transform().basis
	direction += aim.x * (Input.get_action_strength(move_right_action) - Input.get_action_strength(move_left_action))
	direction += aim.z * (Input.get_action_strength(move_backward_action) - Input.get_action_strength(move_forward_action))
	
	direction.y = 0
	direction = direction.normalized()
	
	# Gravity and slopes
	if player.is_on_floor():
		player.has_contact = true
		var n = player.get_node("Tail").get_collision_normal()
		var floor_angle := rad2deg(acos(n.dot(Vector3(0, 1, 0))))
		if floor_angle > player.MAX_SLOPE_ANGLE:
			player.velocity.y += player.gravity * delta
	else:
		if not player.get_node("Tail").is_colliding():
			player.has_contact = false
		player.velocity.y += player.gravity * delta
	
	if player.has_contact and not player.is_on_floor():
		player.move_and_collide(Vector3(0, -1, 0))
	
	var temp_velocity : Vector3 = player.velocity
	temp_velocity.y = 0
	
	var speed : float
	if Input.is_action_pressed(player.run_action) and player.can_run:
		speed = player.MAX_RUNNING_SPEED
	else:
		speed = player.MAX_SPEED
	
	# Max velocity
	var target = direction * speed
	
	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = player.ACCEL
	else:
		acceleration = player.DEACCEL
	
	# Increase the velocity
	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)
	
	player.velocity.x = temp_velocity.x
	player.velocity.z = temp_velocity.z
	
	# Jump (Before moving)
	if Input.is_action_just_pressed(player.jump_action) and player.has_contact:
		player.velocity.y = player.jump_height
		player.has_contact = false
		if player.get_node("Crouch").crouching:
			if get_tree().has_network_peer():
				player.get_node("Crouch").rpc("get_up")
			else:
				player.get_node("Crouch").get_up()
	
	# Move
	player.velocity = player.move_and_slide(player.velocity, Vector3(0, 1, 0), false, 4, deg2rad(player.MAX_SLOPE_ANGLE))
