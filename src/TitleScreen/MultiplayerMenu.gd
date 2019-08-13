extends Control

var joypads_connected : PoolIntArray = []
var keyboard_connected := false
var players_connected := 0
var controller_of_each_player : PoolIntArray = [0, 0, 0, 0]

func _process(delta : float) -> void:
	if players_connected > 1:
		$Play.disabled = false
		if players_connected > 2:
			$OnlinePlay.disabled = true
		else:
			$OnlinePlay.disabled = false
	else:
		$Play.disabled = true
		$OnlinePlay.disabled = true
	
	if !visible:
		return
	
	if Input.is_key_pressed(KEY_Z) and not keyboard_connected:
		keyboard_connected = true
		if players_connected == 0:
			get_node("HBoxContainer/VBoxContainer/1Player").text = "1P KEYBOARD"
			controller_of_each_player[0] = -1
		elif players_connected == 1:
			get_node("HBoxContainer/VBoxContainer2/2Player").text = "2P KEYBOARD"
			controller_of_each_player[1] = -1
		elif players_connected == 2:
			get_node("HBoxContainer/VBoxContainer/3Player").text = "3P KEYBOARD"
			controller_of_each_player[2] = -1
		elif players_connected == 3:
			get_node("HBoxContainer/VBoxContainer2/4Player").text = "4P KEYBOARD"
			controller_of_each_player[3] = -1
		else:
			return
		
		print("Keyboard Connected")
		players_connected += 1
		print("Controllers connected: ", controller_of_each_player)
	
	for joypad in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(joypad, JOY_START):
			if joypads_connected.size() > 0:
				for joypad_connected in joypads_connected:
					if joypad == joypad_connected:
						 return
			
			print(players_connected)
			
			if players_connected == 0:
				get_node("HBoxContainer/VBoxContainer/1Player").text = "1P JOYPAD " + String(joypad)
				controller_of_each_player[0] = joypad + 1
			elif players_connected == 1:
				get_node("HBoxContainer/VBoxContainer2/2Player").text = "2P JOYPAD " + String(joypad)
				controller_of_each_player[1] = joypad + 1
			elif players_connected == 2:
				get_node("HBoxContainer/VBoxContainer/3Player").text = "3P JOYPAD " + String(joypad)
				controller_of_each_player[2] = joypad + 1
			elif players_connected == 3:
				get_node("HBoxContainer/VBoxContainer2/4Player").text = "4P JOYPAD " + String(joypad)
				controller_of_each_player[3] = joypad + 1
			else:
				return
			
			print("Joypad " + String(joypad) + " Connected")
			joypads_connected.push_back(joypad)
			players_connected += 1
			print("Controllers connected: ", controller_of_each_player)
	
	LocalMultiplayer.number_of_players = players_connected
	LocalMultiplayer.controller_of_each_player = controller_of_each_player

func reset_players() -> void:
	LocalMultiplayer.number_of_players = 1
	LocalMultiplayer.controller_of_each_player = [0, 0, 0, 0]
	controller_of_each_player = [0, 0, 0, 0]
	keyboard_connected = false
	players_connected = 0
	joypads_connected = []
	get_node("HBoxContainer/VBoxContainer/1Player").text = "1P"
	get_node("HBoxContainer/VBoxContainer2/2Player").text = "2P"
	get_node("HBoxContainer/VBoxContainer/3Player").text = "3P"
	get_node("HBoxContainer/VBoxContainer2/4Player").text = "4P"
