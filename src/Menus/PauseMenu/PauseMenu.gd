extends Control
class_name PauseMenu

var number_of_player := 0

# Pause
var music_pause_point : float
var resume_music := false
var capture_mouse := false
var paused := false

func _ready() -> void:
	if number_of_player == 0:
		print("ERROR: Number of player unasigned to the pause menu")
		breakpoint

func _process(delta : float) -> void:
	return
	if Input.is_action_just_pressed("pause"):
		if !paused:
			pause_game()
		else:
			resume_game()

func pause_game():
	Utilities.play_button_audio()
	if LocalMultiplayer.number_of_players == 1 and get_node("/root/Main/Music").playing:
		music_pause_point = get_node("/root/Main/Music").get_playback_position()
		resume_music = true
		(get_node("/root/Main/Music") as AudioStreamPlayer).stop()
	show()
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		capture_mouse = true
	else:
		capture_mouse = false
	# GF
	# $PauseMenu/CanvasLayer/Menu/VBoxContainer/ResumeButton.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if LocalMultiplayer.number_of_players == 1:
		get_tree().paused = true
	else:
		pass
		#pause player
	paused = true

func resume_game():
	Utilities.play_button_audio()
	if resume_music:
			(get_node("/root/Main/Music") as AudioStreamPlayer).play(music_pause_point)
	hide() # For buttons
	$Settings.hide()
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# GRAB FOCUS
	# if $SelectionMenu/TeamMenu.visible:
	#	$SelectionMenu/TeamMenu/VBoxContainer/Team1Button.grab_focus()
	# elif $SelectionMenu/ClassMenu.visible:
	#	$SelectionMenu/ClassMenu/VBoxContainer2/Class1Button.grab_focus()
	# elif $SelectionMenu/SpawnMenu.visible:
	#	get_node(get_node("/root/Main/CommandPosts").get_child(0).button_path).grab_focus()
	if LocalMultiplayer.number_of_players == 1:
		get_tree().paused = false
	else:
		pass
		#resume player
	paused = false

func respawn_player():
	return
	
	Utilities.play_button_audio()
	resume_game()
	if $SelectionMenu.player:
		var health_system = $SelectionMenu.player.get_node("HealthSystem")
		if health_system.health != 0:
			if $SelectionMenu.player.get_node("Interaction").is_in_a_vehicle:
				$SelectionMenu.player.get_node("Interaction").current_vehicle.get_node("HealthSystem").take_damage(INF)
			else:
				health_system.take_damage(health_system.MAX_HEALTH)

func _on_SettingsButton_pressed():
	Utilities.play_button_audio()
	if not $PauseMenu/Menu/Settings.visible:
		$PauseMenu/Menu/Settings.show()
	else:
		$PauseMenu/Menu/Settings.hide()

func _on_CheckButton_pressed():
	Utilities.play_button_audio()
	Settings.controller_input = !Settings.controller_input
	Settings.save_settings()
