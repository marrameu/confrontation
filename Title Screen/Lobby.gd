extends Control

var _player_name := ""
var _connect_ip := "127.0.0.1" # Per defecte, está definit com a "localhost", es a dir conexió local

var connecting := false

func _ready() -> void:
	set_process(false)

func _process(delta : float):
	if connecting:
		if get_tree().network_peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
			LocalMultiplayer.remap_inputs()
			get_tree().change_scene('res://Main/Main.tscn')
		else:
			show_loading_screen()
	else:
		hide_loading_screen()
		get_tree().set_network_peer(null)
		set_process(false)

func _on_NameLine_text_changed(new_text : String) -> void:
	_player_name = new_text

func _on_IPLine_text_changed(new_text : String) -> void:
	_connect_ip = new_text

func _on_CreateButton_pressed() -> void:
	if _player_name == "":
		_player_name = "Noname"
	Utilities.play_button_audio()
	Network.create_server(_player_name)
	load_game()

func _on_JoinButton_pressed() -> void:
	if not _connect_ip.is_valid_ip_address():
		return
	if _player_name == "":
		_player_name = "Noname"
	Utilities.play_button_audio()
	Network.connect_to_server(_player_name, _connect_ip)
	load_game()

func load_game():
	connecting = true
	($WaitTimer as Timer).start()
	set_process(true)

func _on_WaitTimer_timeout():
	connecting = false

func show_loading_screen() -> void:
	$"../LoadingScreen".visible = true
	$"../LoadingScreen/Multiplayer".visible = true
	hide()

func hide_loading_screen() -> void:
	$"../LoadingScreen".visible = false
	$"../LoadingScreen/Multiplayer".visible = false
	show()
