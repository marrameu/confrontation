extends Spatial
class_name Main

var game_started := false

var local_players := [null, null, null, null]
var selection_menus := [null, null, null, null]

var players_cameras := [ { }, { }, { }, { } ]

# Clients
var _vehicles_instantiated := false
var _troops_instantiated := false
var _capital_ships_instantiated := false


func _ready() -> void:
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	for i in range(0, players_cameras.size()):
		players_cameras[i] = { troop_camera = null, ship_camera = null, scene_camera = null }
	
	var i := 1
	while i <= LocalMultiplayer.number_of_players:
		_add_new_player(i)
		i += 1
	
	# Scene Camera 4
	if LocalMultiplayer.number_of_players == 3:
		_enable_scene_camera4()
	
	# Destroy vehicles and frigates
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			for vehicle in $Vehicles.get_children():
				vehicle.queue_free()
			
			for ship in $CapitalShips.get_children():
				ship.queue_free()
	
	Settings.apply_settings()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Pròximament
	# if Settings.controller_input:
	#	$PauseMenu/Menu/Settings/CheckButton.pressed = true


func _process(delta : float) -> void:
	if Input.is_key_pressed(KEY_F1):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_key_pressed(KEY_F2):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_key_pressed(KEY_F3):
		$DebugHUD/FPS.show()
	elif Input.is_key_pressed(KEY_F4):
		$DebugHUD/FPS.hide()
	$DebugHUD/FPS.text = str(Engine.get_frames_per_second())
	
	if Input.is_key_pressed(KEY_F5):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -72.0)
	elif Input.is_key_pressed(KEY_F6):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -15.0)
	
	if Input.is_key_pressed(KEY_F9) and Settings.controller_input != false:
		Settings.controller_input = false
		Settings.save_settings()
	elif Input.is_key_pressed(KEY_F10) and Settings.controller_input != true:
		Settings.controller_input = true
		Settings.save_settings()
	
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			if Network.match_data.recived:
				var vehicles_data = Network.match_data.vehicles_data
				var troops_data = Network.match_data.troops_data
				var capital_ships_data = Network.match_data.capital_ships_data
				
				if not _vehicles_instantiated:
					for vehicle_data in vehicles_data:
						_add_new_vehicle(vehicle_data)
					_vehicles_instantiated = true
				
				if not _troops_instantiated:
					for troop_data in troops_data:
						_add_new_troop(troop_data)
					_troops_instantiated = true
				
				if not _capital_ships_instantiated:
					for capital_ship_data in capital_ships_data:
						_add_new_capital_ship(capital_ship_data)
					_capital_ships_instantiated = true


sync func spawn_troops(troops_per_team : int):
	
	var a = troops_per_team
	var b = a
	
	for i in range(troops_per_team * 2):
		var new_troop : Troop = load("res://src/Troops/AI/Troop.tscn").instance()
		new_troop.name = "Troop" + String(i)
		
		#Team
		if a > 0:
			new_troop.get_node("TroopManager").m_team = 1
			a -= 1
		elif b > 0:
			new_troop.get_node("TroopManager").m_team = 2
			b -=1
		
		# Position
		var command_posts := []
		for command_post in get_node("/root/Main/CommandPosts").get_children():
			if command_post.m_team == new_troop.get_node("TroopManager").m_team:
				command_posts.push_back(command_post)
		if command_posts.size() < 1:
			print("ERROR: No command posts")
			return
		var pos : Vector3 = command_posts[randi()%command_posts.size()].translation
		new_troop.translation = Vector3(pos.x + rand_range(-15, 15),  1.815, pos.z + rand_range(-15, 15))
		$Troops.add_child(new_troop)
		
		# Material
		new_troop.set_material()


func exit_game() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://src/TitleScreen/TitleScreen.tscn")
	get_tree().paused = false


func _on_server_disconnected() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	exit_game()
	get_tree().set_network_peer(null)
	for data in Network.self_datas:
		data = { }


func _add_new_player(number : int) -> void:
	# Instance Player
	var new_player : Player = load("res://src/Troops/Player/Player.tscn").instance()
	new_player.number_of_player = number
	local_players[number - 1] = new_player
	
	players_cameras[number - 1].troop_camera = new_player.get_node("CameraBase/Camera")
	players_cameras[number - 1].ship_camera = new_player.get_node("CameraBase/ShipCamera")
	
	# Render
	_add_new_render(number)
	
	# Selection Menu
	_add_selection_menu(number)
	
	# Name for online
	if get_tree().has_network_peer():
		new_player.name = str(get_tree().get_network_unique_id())
		new_player.set_network_master(get_tree().get_network_unique_id())
	else:
		new_player.name = "Player"
	
	var info : Dictionary = Network.self_datas[number - 1]
	new_player.init(info.name, info.position, false, info.health, false, false)


func _add_new_render(number : int) -> void:
	var render : PlayerRender = $Splitscreen.add_player(number - 1)
	
	# Settings
	render.viewport.msaa = get_tree().get_root().msaa
	# Shadows
	
	render.viewport.add_child(local_players[number - 1])
	
	# Pause Menu (Canvas Scaler)
	var pause_menu = load("res://src/Menus/PauseMenu/PauseMenu.tscn").instance() # : PauseMenu
	pause_menu.number_of_player = 1
	render.add_child(pause_menu)
	
	# Scene Camera
	var scene_camera : Camera = get_node("Cameras/SceneCamera" + str(number))
	scene_camera.make_current()
	$Cameras.remove_child(scene_camera)
	render.viewport.add_child(scene_camera)
	
	players_cameras[number - 1].scene_camera = scene_camera


func _add_selection_menu(number : int) -> void:
	var selection_menu : SelectionMenu = load("res://src/Menus/SelectionMenu/SelectionMenu.tscn").instance()
	selection_menu.number_of_player = number
	$SelectionMenus.add_child(selection_menu) # Canviar?
	selection_menus[number - 1] = selection_menu


# Canviar
func _enable_scene_camera4() -> void:
	var render4 = $Splitscreen.add_player(3)
	render4.name = "Ignore"
	render4.viewport.msaa = get_tree().get_root().msaa
	
	var scene_camera4 = $Cameras/SceneCamera4
	remove_child(scene_camera4)
	render4.viewport.add_child(scene_camera4)
	scene_camera4.make_current()
	
	scene_camera4.translation = Vector3(0, 300, 0)
	scene_camera4.rotation = Vector3(deg2rad(-90), 0, 0)


func _add_new_vehicle(vehicle_data : Dictionary) -> void:
	var vehicle_scene = load(vehicle_data.vehicle_res)
	var new_vehicle : Spatial = vehicle_scene.instance()
	new_vehicle.translation = vehicle_data.position
	new_vehicle.rotation = vehicle_data.rotation
	new_vehicle.name = vehicle_data.vehicle_name
	new_vehicle.get_node("HealthSystem").health = vehicle_data.health
	new_vehicle.is_player = vehicle_data.is_player
	new_vehicle.state = vehicle_data.state
	if vehicle_data.team != 0:
		new_vehicle.get_node("Transport").m_team = vehicle_data.team
	if vehicle_data.is_player:
		new_vehicle.player_name = String(vehicle_data.player_id)
	$Vehicles.add_child(new_vehicle)


func _add_new_capital_ship(capital_ship_data : Dictionary) -> void:
	var ship_scene = load("res://src/CapitalShips/CapitalShip.tscn")
	var new_ship : Spatial = ship_scene.instance()
	if capital_ship_data.name == "CapitalShip":
		new_ship.translation = Vector3(0, 2000, 2000)
		new_ship.rotation_degrees = Vector3(0, 90, 0)
	elif capital_ship_data.name == "CapitalShip2":
		new_ship.name = "CapitalShip2"
		new_ship.translation = Vector3(0, 2000, -2000)
		new_ship.rotation_degrees = Vector3(0, -90, 0)
		new_ship.get_node("Label").rect_position.y -= 50
	new_ship.get_node("HealthSystem").health = capital_ship_data.health
	if capital_ship_data.health == 0:
		new_ship._on_HealthSystem_die()
	$CapitalShips.add_child(new_ship)


func _add_new_troop(troop_data : Dictionary) -> void:
	var troop_scene = load("res://src/Troops/AI/Troop.tscn")
	var new_troop : Troop = troop_scene.instance()
	new_troop.name = troop_data.name
	new_troop.translation = troop_data.position
	new_troop.rotation = troop_data.rotation
	new_troop.get_node("TroopManager").m_team = troop_data.team
	if troop_data.is_alive:
		new_troop.get_node("TroopManager").is_alive = true
		new_troop.get_node("HealthSystem").health = troop_data.health
	else:
		new_troop.get_node("TroopManager").is_alive = false
		new_troop.get_node("HealthSystem").health = 0
	new_troop.init()
	$Troops.add_child(new_troop)
