extends Node

var input_manager : InputManager
var input_map : Dictionary

func _ready() -> void:
	$Player.set_process(false)
	$AI.set_process(false)
	get_parent().set_mode(RigidBody.MODE_KINEMATIC)

func _process(delta: float) -> void:
	if get_parent().is_player and not input_manager:
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
	var ship_camera : Camera = get_node("/root/Main").players_cameras[get_parent().number_of_player - 1].ship_camera
	var player : Player = get_node("/root/Main").local_players[get_parent().number_of_player - 1]
	if not player: # Mirar si es pot treure aquesta comporvació
		return
	input_manager = player.get_node("InputManager")
	input_map = input_manager.input_map
	
	$Player.input_device = input_manager.number_of_device
	
	$Player.move_right_action = input_map.move_right
	$Player.move_left_action = input_map.move_left
	$Player.move_forward_action = input_map.move_forward
	$Player.move_backward_action = input_map.move_backward
	
	$Player.camera_right_action = input_map.camera_right
	$Player.camera_left_action = input_map.camera_left
	$Player.camera_up_action = input_map.camera_up
	$Player.camera_down_action = input_map.camera_down
	
	get_parent().jump_action = input_map.jump
	get_node("../Shooting").shoot_action = input_map.shoot
	get_node("../Shooting").zoom_action = input_map.zoom
	
	ship_camera.input_device = input_manager.number_of_device
	
	ship_camera.zoom_ship_action = input_map.zoom_ship
	ship_camera.look_behind_action = input_map.look_behind
	ship_camera.camera_right_action = input_map.camera_right
	ship_camera.camera_left_action = input_map.camera_left
	ship_camera.camera_up_action = input_map.camera_up
	ship_camera.camera_down_action = input_map.camera_down
