extends Node

var number_of_players := 1
var controller_of_each_player := [0, 0, 0, 0]

const KEY := 0
const MOUSE_BUTTON := 1
const JOY_BUTTON := 2
const AXIS := 3

func remap_inputs() -> void:
	if number_of_players == 1:
		return
	
	# CREAR FUNCIÓN
	for i in range(0, controller_of_each_player.size()):
		if controller_of_each_player[i] == 0:
			break
		
		# 1 ARREGLAR ESTO
		var a := String(i + 1)
		if controller_of_each_player[i] == -1:
			add_action("shoot_player_" + a, BUTTON_LEFT, MOUSE_BUTTON)
			add_action("move_forward_player_" + a, KEY_W, KEY)
			add_action("move_backward_player_" + a, KEY_S, KEY)
			add_action("move_left_player_" + a, KEY_A, KEY)
			add_action("move_right_player_" + a, KEY_D, KEY)
			add_action("jump_player_" + a, KEY_SPACE, KEY)
			add_action("run_player_" + a, KEY_SHIFT, KEY)
			add_action("crounch_player_" + a, KEY_CONTROL, KEY)
			add_action("zoom_player_" + a, BUTTON_RIGHT, MOUSE_BUTTON)
			add_action("pause_player_" + a, KEY_ESCAPE, KEY) 
			add_action("interact_player_" + a, KEY_E, KEY)
			add_action("change_view_player_" + a, KEY_C, KEY)
			add_action("look_behind_player_" + a, KEY_Q, KEY)
			add_action("zoom_ship_player_" + a, BUTTON_MIDDLE, MOUSE_BUTTON)
		else:
			var device : int = controller_of_each_player[i] - 1
			add_action("shoot_player_" + a, JOY_R2, JOY_BUTTON, device)
			add_action("move_forward_player_" + a, JOY_AXIS_1, AXIS, device, -1.0)
			add_action("move_backward_player_" + a, JOY_AXIS_1, AXIS, device, 1.0)
			add_action("move_left_player_" + a, JOY_AXIS_0, AXIS, device, -1.0)
			add_action("move_right_player_" + a, JOY_AXIS_0, AXIS, device, 1.0)
			add_action("jump_player_" + a, JOY_BUTTON_0, JOY_BUTTON, device)
			add_action("run_player_" + a, JOY_BUTTON_4, JOY_BUTTON, device)
			add_action("crounch_player_" + a, JOY_BUTTON_1, JOY_BUTTON, device)
			add_action("camera_up_player_" + a, JOY_AXIS_3, AXIS, device, -1.0)
			add_action("camera_down_player_" + a, JOY_AXIS_3, AXIS, device, 1.0)
			add_action("camera_right_player_" + a, JOY_AXIS_2, AXIS, device, 1.0)
			add_action("camera_left_player_" + a, JOY_AXIS_2, AXIS, device, -1.0)
			add_action("zoom_player_" + a, JOY_L2, JOY_BUTTON, device)
			add_action("pause_player_" + a, JOY_BUTTON_7, JOY_BUTTON, device) 
			add_action("interact_player_" + a, JOY_BUTTON_3, JOY_BUTTON, device)
			add_action("change_view_player_" + a, JOY_DPAD_DOWN, JOY_BUTTON, device)
			add_action("look_behind_player_" + a, JOY_DPAD_DOWN, JOY_BUTTON, device)
			add_action("zoom_ship_player_" + a, JOY_DPAD_UP, JOY_BUTTON, device)

func add_action(action_name : String, event_scancode : int, type : int, device := 0, axis_value := 0.0) -> void:
	var deadzone := 0.1
	InputMap.add_action(action_name, deadzone)
	var new_event
	if type == MOUSE_BUTTON:
		new_event = InputEventMouseButton.new()
		new_event.set_button_index(event_scancode)
	elif type == KEY:
		new_event = InputEventKey.new()
		new_event.set_scancode(event_scancode)
	elif type == JOY_BUTTON:
		new_event = InputEventJoypadButton.new()
		new_event.set_device(device)
		new_event.set_button_index(event_scancode)
	elif type == AXIS:
		new_event = InputEventJoypadMotion.new()
		new_event.set_device(device)
		new_event.set_axis(event_scancode)
		new_event.set_axis_value(axis_value)
	InputMap.action_add_event(action_name, new_event)
