extends Control

var loader : ResourceInteractiveLoader
var changing_scene : bool = false


func _ready() -> void:
	$Menu/Buttons/SinglePlayer.grab_focus()


func _on_Play_pressed() -> void:
	if LocalMultiplayer.number_of_players == 0:
		return
	Utilities.play_button_audio()
	$Menu.hide()
	$MultiplayerMenu.hide()
	$LoadingScreen/SinglePlayer.show()
	LocalMultiplayer.remap_inputs()
	load_scene("res://src/Main/Main.tscn")


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


func _process(delta : float) -> void:
	if changing_scene:
		if not loader:
			changing_scene = false
			return
		
		var err = loader.poll()
		if err == ERR_FILE_EOF: # Finished loading
			var resource = loader.get_resource()
			loader = null
			get_tree().change_scene_to(resource)
		elif err == OK:
			update_progress()
		else: # Error during loading
			loader = null


func load_scene(path : String) -> void:
	loader = ResourceLoader.load_interactive(path)
	if loader == null:
		return
	changing_scene = true
	$LoadingScreen.show()


# Fer-la servir en un futur
func update_progress() -> void:
	var progress : float = float(loader.get_stage()) / loader.get_stage_count()


# Fer-la servir en un futur
func set_new_scene(scene_resource : PackedScene) -> void:
	var new_scene = scene_resource.instance()
	get_node("/root").add_child(new_scene)
