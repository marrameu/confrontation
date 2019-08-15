extends CanvasLayer
class_name SelectionMenu

var player : KinematicBody = null # : Player
var current_cp : CommandPost = null

var number_of_player := 0

func _ready() -> void:
	if LocalMultiplayer.number_of_players > 1:
		scale = Vector2(0.5, 0.5)
		offset = Vector2(480, 0) if number_of_player == 1 else Vector2(480, 540)
	
	# $Container/TeamMenu/VBoxContainer/Team1Button.grab_focus()


func _set_team(selected_team : int) -> void:
	Utilities.play_button_audio()
	player = get_node("/root/Main").local_players[number_of_player - 1]
	player.get_node("TroopManager").m_team = selected_team
	
	if get_tree().has_network_peer():
		Network.players[number_of_player - 1][int(player.name)].team = selected_team
		Network.rpc("_send_player_config", int(player.name), selected_team, number_of_player)
	
	for troop in get_node("/root/Main/Troops").get_children():
		troop.set_material()
	
	$Container/TeamMenu.hide()
	$Container/ClassMenu.show()
	# GRAB FOCUS
	# $Container/ClassMenu/VBoxContainer2/Class1Button.grab_focus()


func _set_class(selected_class : int) -> void:
	Utilities.play_button_audio()
	$Container/ClassMenu.hide()
	$Container/SpawnMenu.show() 
	# get_node(get_node("/root/Main/CommandPosts").get_child(0).button_path).grab_focus()
	
	player.get_node("TroopManager").m_class = selected_class
	
	var scene_camera : Camera = get_node("/root/Main").players_cameras[number_of_player - 1].scene_camera
	if scene_camera:
		scene_camera.translation = Vector3(0, 300, 0)
		scene_camera.rotation_degrees = Vector3(-90, 0, 0)


func _on_SpawnButton_pressed() -> void:
	 # Per als transports
	var wr = weakref(current_cp)
	if not wr.get_ref():
		$Container/SpawnMenu/SpawnButton.hide()
		return
	
	# Per si canvia d'equip
	if current_cp.m_team != player.get_node("TroopManager").m_team:
		$Container/SpawnMenu/SpawnButton.hide()
		return
	
	Utilities.play_button_audio()
	$Container/SpawnMenu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not get_node("/root/Main").game_started:
		get_node("/root/Main/Music").play()
		if get_tree().has_network_peer():
			"""
			Millorar: que només iniciar la partida en X segons (si hi ha més d'un jugador) comencin a fer spawn les tropes
			Es necesitarà la camara d'espectador
			"""
			if get_tree().is_network_server():
				if get_node("/root/Main/Troops").get_child_count() == 0:
					get_node("/root/Main").rpc("spawn_troops", 32)
			else:
				if Network.match_data.recived and get_node("/root/Main/Troops").get_child_count() == 0:
					get_node("/root/Main").rpc("spawn_troops", 32)
		else:
			get_node("/root/Main").spawn_troops(32)
		get_node("/root/Main").game_started = true
	
	if get_tree().has_network_peer():
		player.rpc("respawn")
	else:
		player.respawn()


func _on_CommandPostButton_pressed(command_post : CommandPost) -> void:
	var cp_pos := command_post.translation
	var cp_team := command_post.m_team
	
	if cp_team == player.get_node("TroopManager").m_team:
		Utilities.play_button_audio()
		current_cp = command_post
		player.spawn_position = cp_pos + Vector3(0, 2, 0)
		$Container/SpawnMenu/SpawnButton.show()


func _on_ViewButton_pressed():
	Utilities.play_button_audio()
	var scene_camera : Camera = get_node("/root/Main").players_cameras[number_of_player - 1].scene_camera
	var ground_view := scene_camera.translation.y < 1000
	
	scene_camera.translation = Vector3(0, 5000, 0) if ground_view else Vector3(0, 300, 0)
	scene_camera.rotation_degrees = Vector3(-90, 90, 0) if ground_view else Vector3(-90, 0, 0)
	scene_camera.far = 5500 if ground_view else 550
