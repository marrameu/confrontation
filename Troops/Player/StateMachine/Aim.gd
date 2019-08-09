extends "res://Troops/Player/StateMachine/State.gd"

func _ready():
	pass

func aim() -> void:
	var player : KinematicBody = get_node("../../..") # : Player
	
	if LocalMultiplayer.number_of_players == 1 or player.get_node("InputManager").number_of_device == -1:
		player.mouse_movement = Utilities.mouse_movement * player.mouse_sensitivity
	player.get_node("CameraBase").input_movement = player.joystick_movement + player.mouse_movement
	player.camera_change += player.joystick_movement + player.mouse_movement
	if player.camera_change.length() > 0:
		# Rotate camera [X]
		player.camera_x_rot = clamp(-player.get_node("CameraBase").rotation.x + player.camera_change.y, deg2rad(player.CAMERA_X_ROT_MIN), deg2rad(player.CAMERA_X_ROT_MAX))
		player.get_node("CameraBase").rotation.x = -player.camera_x_rot
		player.get_node("CameraBase").orthonormalize()
		# Rotate player [Y]
		player.rotate_y(-player.camera_change.x)
		player.orthonormalize()
		# Reset camera input
		player.camera_change = Vector2()
		player.joystick_movement = Vector2()
