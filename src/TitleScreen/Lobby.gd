extends Control

var _player_name := "Noname"
onready var _connect_ip := Network.DEFAULT_IP

var create := false
var connecting := false

var scene_resource : Resource


func _ready() -> void:
	set_process(false)


func _process(delta : float):
	if connecting:
		if get_tree().network_peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
			LocalMultiplayer.remap_inputs()
			get_tree().change_scene_to(scene_resource)
	else:
		get_parent().hide_loading_screen()
		show()
		
		get_tree().set_network_peer(null)
		set_process(false)
		
		scene_resource = null


func _on_NameLine_text_changed(new_text : String) -> void:
	_player_name = new_text if new_text else "Noname"


func _on_IPLine_text_changed(new_text : String) -> void:
	_connect_ip = new_text if new_text else Network.DEFAULT_IP


func _on_CreateButton_pressed() -> void:
	Utilities.play_button_audio()
	create = true
	get_parent().load_scene('res://src/Main/Main.tscn', false)
	get_parent().show_loading_screen(false)


func _on_JoinButton_pressed() -> void:
	if not _connect_ip.is_valid_ip_address():
		return
	
	Utilities.play_button_audio()
	create = false
	get_parent().load_scene('res://src/Main/Main.tscn', false)
	get_parent().show_loading_screen(false)


func _on_WaitTimer_timeout():
	connecting = false


func _on_TitleScreen_finished_loading(resource : Resource):
	connecting = true
	$WaitTimer.start()
	get_parent().show_loading_screen(true)
	scene_resource = resource
	set_process(true)
	
	if create:
		Network.create_server(_player_name)
	else:
		Network.connect_to_server(_player_name, _connect_ip)
