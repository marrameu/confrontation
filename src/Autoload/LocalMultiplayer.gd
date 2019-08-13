extends Node

var number_of_players := 1
var controller_of_each_player : PoolIntArray = [0, 0, 0, 0]

enum Event { KEY, MOUSE_BUTTON, JOY_BUTTON, AXIS }

func remap_inputs() -> void:
	if number_of_players == 1:
		return
	
	for i in range(0, controller_of_each_player.size()):
		if controller_of_each_player[i] == 0:
			break
		
		var a := String(i + 1)
		if controller_of_each_player[i] == -1:
			add_action("shoot_player_" + a, BUTTON_LEFT, Event.MOUSE_BUTTON)
			add_action("move_forward_player_" + a, KEY_W, Event.KEY)
			add_action("move_backward_player_" + a, KEY_S, Event.KEY)
			add_action("move_left_player_" + a, KEY_A, Event.KEY)
			add_action("move_right_player_" + a, KEY_D, Event.KEY)
			add_action("jump_player_" + a, KEY_SPACE, Event.KEY)
			add_action("run_player_" + a, KEY_SHIFT, Event.KEY)
			add_action("crouch_player_" + a, KEY_CONTROL, Event.KEY)
			add_action("zoom_player_" + a, BUTTON_RIGHT, Event.MOUSE_BUTTON)
			add_action("pause_player_" + a, KEY_ESCAPE, Event.KEY) 
			add_action("interact_player_" + a, KEY_E, Event.KEY)
			add_action("change_view_player_" + a, KEY_C, Event.KEY)
			add_action("look_behind_player_" + a, KEY_Q, Event.KEY)
			add_action("zoom_ship_player_" + a, BUTTON_MIDDLE, Event.MOUSE_BUTTON)
		else:
			var device : int = controller_of_each_player[i] - 1
			add_action("shoot_player_" + a, JOY_R2, Event.JOY_BUTTON, device)
			add_action("move_forward_player_" + a, JOY_AXIS_1, Event.AXIS, device, -1.0)
			add_action("move_backward_player_" + a, JOY_AXIS_1, Event.AXIS, device, 1.0)
			add_action("move_left_player_" + a, JOY_AXIS_0, Event.AXIS, device, -1.0)
			add_action("move_right_player_" + a, JOY_AXIS_0, Event.AXIS, device, 1.0)
			add_action("jump_player_" + a, JOY_BUTTON_0, Event.JOY_BUTTON, device)
			add_action("run_player_" + a, JOY_BUTTON_4, Event.JOY_BUTTON, device)
			add_action("crouch_player_" + a, JOY_BUTTON_1, Event.JOY_BUTTON, device)
			add_action("camera_up_player_" + a, JOY_AXIS_3, Event.AXIS, device, -1.0)
			add_action("camera_down_player_" + a, JOY_AXIS_3, Event.AXIS, device, 1.0)
			add_action("camera_right_player_" + a, JOY_AXIS_2, Event.AXIS, device, 1.0)
			add_action("camera_left_player_" + a, JOY_AXIS_2, Event.AXIS, device, -1.0)
			add_action("zoom_player_" + a, JOY_L2, Event.JOY_BUTTON, device)
			add_action("pause_player_" + a, JOY_BUTTON_7, Event.JOY_BUTTON, device) 
			add_action("interact_player_" + a, JOY_BUTTON_3, Event.JOY_BUTTON, device)
			add_action("change_view_player_" + a, JOY_DPAD_DOWN, Event.JOY_BUTTON, device)
			add_action("look_behind_player_" + a, JOY_DPAD_DOWN, Event.JOY_BUTTON, device)
			add_action("zoom_ship_player_" + a, JOY_DPAD_UP, Event.JOY_BUTTON, device)

func add_action(action : String, event_scancode : int, type : int, device := 0, axis_value := 0.0) -> void:
	var deadzone := 0.2
	InputMap.add_action(action, deadzone)
	var new_event
	if type == Event.MOUSE_BUTTON:
		new_event = InputEventMouseButton.new()
		new_event.set_button_index(event_scancode)
	elif type == Event.KEY:
		new_event = InputEventKey.new()
		new_event.set_scancode(event_scancode)
	elif type == Event.JOY_BUTTON:
		new_event = InputEventJoypadButton.new()
		new_event.set_device(device)
		new_event.set_button_index(event_scancode)
	elif type == Event.AXIS:
		new_event = InputEventJoypadMotion.new()
		new_event.set_device(device)
		new_event.set_axis(event_scancode)
		new_event.set_axis_value(axis_value)
	InputMap.action_add_event(action, new_event)
