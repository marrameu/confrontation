extends Control

# GRAB FOCUS AÚN NO

var player : Player
var number_of_player := 0
var current_cp : CommandPost = null

func _ready() -> void:
	if number_of_player == 0:
		print("ERROR: Number of player unasigned to the selection menu")
		breakpoint
	
	# GRAB FOCUS
	# $TeamMenu/VBoxContainer/Team1Button.grab_focus()

func _set_team(selected_team : int) -> void:
	Utilities.play_button_audio()
	player = ProjectSettings.get("player" + String(number_of_player))
	player.get_node("TroopManager").m_team = selected_team
	
	if get_tree().has_network_peer():
		if number_of_player == 1:
			Network.players1[int(player.name)].team = selected_team
		else:
			Network.players2[int(player.name)].team = selected_team
		Network.rpc("_send_player_config", int(player.name), selected_team, number_of_player)
	
	$TeamMenu.hide()
	$ClassMenu.show()
	# GRAB FOCUS
	# $ClassMenu/VBoxContainer2/Class1Button.grab_focus()

func _set_class(s_class : int) -> void:
	Utilities.play_button_audio()
	player.get_node("TroopManager").m_class = s_class
	$ClassMenu.hide()
	$SpawnMenu.show()
	# GRAB FOCUS
	# get_node(get_node("/root/Main/CommandPosts").get_child(0).button_path).grab_focus()
	
	# Scene Camera 
	var scene_camera : Camera = ProjectSettings.get("scene_camera_" + String(number_of_player))
	if scene_camera:
		scene_camera.translation = Vector3(0, 300, 0)
		scene_camera.rotation = Vector3(deg2rad(-90), 0, 0)

func _on_SpawnButton_pressed() -> void:
	if current_cp == null: # For transports
		$SpawnMenu/SpawnButton.hide()
		return
	elif current_cp.m_team != player.get_node("TroopManager").m_team:
		$SpawnMenu/SpawnButton.hide()
		return
	
	Utilities.play_button_audio()
	if get_tree().has_network_peer():
		player.rpc("respawn")
	else:
		player.respawn()
	$SpawnMenu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not get_node("/root/Main").game_started:
		(get_node("/root/Main/Music") as AudioStreamPlayer).play()
		if get_tree().has_network_peer():
			if get_tree().is_network_server():
				get_node("/root/Main").rpc("spawn_troops", 32)
		else:
			get_node("/root/Main").spawn_troops(32)
		get_node("/root/Main").game_started = true

func _on_CommandPostButton_pressed(command_post : CommandPost) -> void:
	var cp_pos : Vector3 = command_post.translation
	var cp_team : int = command_post.m_team
	if cp_team == player.get_node("TroopManager").m_team:
		Utilities.play_button_audio()
		$SpawnMenu/SpawnButton.show()
		player.spawn_position = cp_pos + Vector3(0, 2, 0)
		current_cp = command_post

func _on_ViewButton_pressed():
	Utilities.play_button_audio()
	var scene_camera : Camera = ProjectSettings.get("scene_camera_" + String(number_of_player))
	if scene_camera:
		if scene_camera.translation.y > 300:
			scene_camera.translation = Vector3(0, 300, 0)
			scene_camera.rotation_degrees = Vector3(-90, 0, 0)
			scene_camera.far = 550 # CHANGE WHEN ADDING EXPONENTAIL FOG
		else:
			scene_camera.translation = Vector3(0, 5000, 0)
			scene_camera.rotation_degrees = Vector3(-90, 90, 0)
			scene_camera.far = 5500 # CHANGE WHEN ADDING EXPONENTAIL FOG
