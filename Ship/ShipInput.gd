extends Node

var input_manager : InputManager
var input_map : Dictionary

func _ready() -> void:
	$Player.set_process(false)
	$AI.set_process(false)
	get_parent().set_mode(RigidBody.MODE_KINEMATIC)

func _process(delta: float) -> void:
	if get_parent().is_player and input_manager == null:
		if LocalMultiplayer.number_of_players > 1:
			if get_tree().has_network_peer():
				if get_parent().is_network_master():
					set_player_input()
			else:
				set_player_input()
	elif not get_parent().is_player:
		input_manager = null
	
	if get_parent().is_player and get_parent().state == 1:
		$Player.set_process(true)
	else:
		$Player.set_process(false)
		$Player.throttle = 0.0
		$Player.strafe = 0.0

func set_player_input() -> void:
	var ship_camera : Camera = ProjectSettings.get("ship_camera" + String(get_parent().number_of_player))
	var player : Player = ProjectSettings.get("player" + String(get_parent().number_of_player))
	input_manager = player.get_node("InputManager")
	input_map = input_manager.input_map
	
	$Player.input_device = input_manager.number_of_device
	
	$Player.move_right_action_name = input_map.move_right
	$Player.move_left_action_name = input_map.move_left
	$Player.move_forward_action_name = input_map.move_forward
	$Player.move_backward_action_name = input_map.move_backward
	
	$Player.camera_right_action_name = input_map.camera_right
	$Player.camera_left_action_name = input_map.camera_left
	$Player.camera_up_action_name = input_map.camera_up
	$Player.camera_down_action_name = input_map.camera_down
	
	get_parent().jump_action_name = input_map.jump
	get_node("../Shooting").shoot_action_name = input_map.shoot
	get_node("../Shooting").zoom_action_name = input_map.zoom
	
	ship_camera.input_device = input_manager.number_of_device
	
	ship_camera.zoom_ship_action_name = input_map.zoom_ship
	ship_camera.look_behind_action_name = input_map.look_behind
	ship_camera.camera_right_action_name = input_map.camera_right
	ship_camera.camera_left_action_name = input_map.camera_left
	ship_camera.camera_up_action_name = input_map.camera_up
	ship_camera.camera_down_action_name = input_map.camera_down
