extends Control

var loader : ResourceInteractiveLoader
var changing_scene : bool = false
var emit_signal : bool = false

signal finished_loading


func _ready() -> void:
	$Menu/Buttons/SinglePlayer.grab_focus()


func _on_Play_pressed() -> void:
	if LocalMultiplayer.number_of_players == 0:
		return
	Utilities.play_button_audio()
	LocalMultiplayer.remap_inputs()
	show_loading_screen(false)
	load_scene("res://src/Main/Main.tscn", true)


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_Back_pressed() -> void:
	Utilities.play_button_audio()
	$Menu.show()
	$SettingsMenu.hide()
	$Lobby.hide()
	$MultiplayerMenu.hide()
	$Menu/Buttons/SinglePlayer.grab_focus()


func _on_MultiplayerBack_pressed():
	$MultiplayerMenu.reset_players()


func _on_Settings_pressed() -> void:
	Utilities.play_button_audio()
	$SettingsMenu.show()
	$Menu.hide()
	$SettingsMenu/Back.grab_focus()


func _on_Multiplayer_pressed() -> void:
	Utilities.play_button_audio()
	$MultiplayerMenu.show()
	$Menu.hide()
	$MultiplayerMenu/Back.grab_focus()


func _on_OnlinePlay_pressed() -> void:
	Utilities.play_button_audio()
	$Lobby.show()
	$Menu.hide()
	$MultiplayerMenu.hide()
	$Lobby/Back.grab_focus()


func show_loading_screen(online : bool) -> void:
	$Menu.hide()
	$Lobby.hide()
	$MultiplayerMenu.hide()
	$LoadingScreen.show()
	
	$LoadingScreen/Multiplayer.visible = online
	$LoadingScreen/SinglePlayer.visible = !online
	$LoadingScreen/ProgressBar.visible = !online


func hide_loading_screen() -> void:
	$LoadingScreen.hide()
	$LoadingScreen/Multiplayer.hide()
	$LoadingScreen/SinglePlayer.hide()
	$LoadingScreen/ProgressBar.hide()


func _process(delta : float) -> void:
	if changing_scene:
		if not loader:
			changing_scene = false
			return
		
		_process_load_scene()


func _process_load_scene() -> void:
	var err = loader.poll()
	if err == ERR_FILE_EOF: # Finished loading
		var resource = loader.get_resource()
		loader = null
		
		if emit_signal:
			emit_signal("finished_loading", resource)
		else:
			get_tree().change_scene_to(resource)
		
	elif err == OK:
		update_progress()
		
	else: # Error during loading
		loader = null


func load_scene(path : String, instant_load : bool) -> void:
	loader = ResourceLoader.load_interactive(path)
	emit_signal = !instant_load
	if loader == null:
		return
	changing_scene = true


func update_progress() -> void:
	var progress : float = float(loader.get_stage()) / loader.get_stage_count()
	$LoadingScreen/ProgressBar.value = progress * 100
