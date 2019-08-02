extends Spatial

var game_started := false

# Client
var _vehicles_instantiated := false
var _troops_instantiated := false
var _capital_ships_instantiated := false

var local_players := [null, null, null, null]
var selection_menus := [null, null, null, null]


# Crear una funció per a crear un nou jugador local
func _ready() -> void:
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
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
					# Passar el nom per match_data en el futur
					for vehicle_data in vehicles_data:
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
					_vehicles_instantiated = true
				
				if not _troops_instantiated:
					for troop_data in troops_data:
						var troop_scene = load("res://Troops/NPC Troop/Troop.tscn")
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
						set_troop_material(new_troop)
						new_troop.init()
						$Troops.add_child(new_troop)
					_troops_instantiated = true
				
				if not _capital_ships_instantiated:
					for capital_ship_data in capital_ships_data:
						var ship_scene = load("res://Capital Ships/CapitalShip.tscn")
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
					_capital_ships_instantiated = true


sync func spawn_troops(i : int):
# warning-ignore:integer_division
	var a = i / 2
	var b = a
	
	while i > 0:
		i -= 1
		var new_troop : Troop = preload("res://Troops/NPC Troop/Troop.tscn").instance()
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
			return
		var pos : Vector3 = command_posts[randi()%command_posts.size()].translation
		new_troop.translation = Vector3(pos.x + rand_range(-15, 15),  0, pos.z + rand_range(-15, 15))
		$Troops.add_child(new_troop)
		
		# Material
		set_troop_material(new_troop)


func exit_game() -> void:
	ProjectSettings.set("player1", null)
	ProjectSettings.set("player2", null)
	ProjectSettings.set("player3", null)
	ProjectSettings.set("player4", null)
	ProjectSettings.set("scene_camera_1", null)
	ProjectSettings.set("scene_camera_2", null)
	ProjectSettings.set("scene_camera_3", null)
	ProjectSettings.set("scene_camera_4", null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://Title Screen/TitleScreen.tscn")
	get_tree().paused = false


func _on_server_disconnected() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	exit_game()
	get_tree().set_network_peer(null)
	Network.self_data1 = { name = "", position = Vector3(0, 2, 0), rotation = 0.0,
			health = 0, is_alive = false, team = 0, is_in_a_vehicle = false }
	Network.self_data2 = { name = "", position = Vector3(0, 2, 0), rotation = 0.0,
			health = 0, is_alive = false, team = 0, is_in_a_vehicle = false }


func set_troop_material(new_troop : Troop) -> void:
	# Millorar
	if new_troop.get_node("TroopManager").m_team == 1:
		new_troop.get_node("MeshInstance").set_material_override(preload("res://Command Post/Blue.tres"))
	else:
		new_troop.get_node("MeshInstance").set_material_override(preload("res://Command Post/Red.tres"))


func _add_new_player(number : int) -> void:
	# Instance Player
	var new_player : Player = load("res://Troops/Player/Player.tscn").instance()
	local_players[number - 1] = new_player
	local_players[number - 1].number_of_player = number
	
	# Render
	_add_new_render(number)
	
	# Canviar
	ProjectSettings.set("player" + str(number), local_players[number - 1])
	
	# Selection Menu
	_add_selection_menu(number)
	
	# Name for online
	if get_tree().has_network_peer():
		new_player.name = str(get_tree().get_network_unique_id())
		new_player.set_network_master(get_tree().get_network_unique_id())
	else:
		new_player.name = "Player"
	
	var info : Dictionary = Network.get("self_data" + str(number))
	new_player.init(info.name, info.position, false, info.health, false, false)


func _add_new_render(number : int) -> void:
	var render : PlayerRender = $Splitscreen.add_player(number - 1)
	
	# Settings
	render.viewport.msaa = get_tree().get_root().msaa
	# Shadows
	
	render.viewport.add_child(local_players[number - 1])
	
	# Pause Menu (Canvas Scaler)
	var pause_menu : PauseMenu = load("res://Menus/PauseMenu.tscn").instance()
	pause_menu.number_of_player = 1
	render.add_child(pause_menu)
	
	# Scene Camera
	var scene_camera : Camera = get_node("SceneCamera" + str(number))
	scene_camera.current = true
	remove_child(scene_camera)
	render.viewport.add_child(scene_camera)
	# Canviar
	ProjectSettings.set("scene_camera_" + str(number), scene_camera)


func _add_selection_menu(number : int) -> void:
	var selection_menu : SelectionMenu = load("res://Menus/Selection Menu/SelectionMenu.tscn").instance()
	selection_menu.number_of_player = number
	$SelectionMenus.add_child(selection_menu) # Canviar?
	selection_menus[number - 1] = selection_menu


func _enable_scene_camera4() -> void:
	var render4 = $Splitscreen.add_player(3)
	render4.name = "IGNORE"
	render4.viewport.msaa = get_tree().get_root().msaa
	var scene_camera4 = $SceneCamera4 # CHANGE
	remove_child(scene_camera4)
	render4.viewport.add_child(scene_camera4)
	scene_camera4.current = true
	scene_camera4.translation = Vector3(0, 300, 0)
	scene_camera4.rotation = Vector3(deg2rad(-90), 0, 0)
