extends "res://Troops/Player/StateMachine/State.gd"

func enter():
	pass

func handle_input(event):
	return .handle_input(event)

func update(delta):
	var input_move_direction = get_move_input_direction()
	var input_aim_direction = get_aim_input_direction()
	if input_move_direction:
		emit_signal("finished", "move")
		#print("finished, move")
	if input_aim_direction:
		emit_signal("finished", "aim")
		#print("finished, aim")

func get_move_input_direction():
	var input_direction = Vector2()
	input_direction.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	input_direction.y = int(Input.is_action_pressed("move_forward")) - int(Input.is_action_pressed("move_backward"))
	return input_direction

func get_aim_input_direction():
	var input_direction = Vector2()
	input_direction = Utilities.mouse_movement
	return input_direction
