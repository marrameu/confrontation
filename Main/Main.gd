extends Spatial

var game_started := false

# Client
var vehicles_instantiated := false
var troops_instantiated := false
var capital_ships_instantiated := false

# Crear una funció per a crear un nou jugador local
func _ready() -> void:
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	var new_players := [null, null, null, null]
	var selection_menus := [null, null, null, null]
	
	if LocalMultiplayer.number_of_players >= 1:
		var new_player : Player = preload("res://Troops/Player/Player.tscn").instance()
		new_players[0] = new_player
		var render = $Splitscreen.add_player(0)
		render.viewport.msaa = get_tree().get_root().msaa
		# render.viewport.shadow_atlas_size = get_tree().get_root().shadow_atlas_size # ProjectSettings.get[...]
		new_players[0].number_of_player = 1
		render.viewport.add_child(new_players[0])
		var scene_camera = $SceneCamera # CHANGE
		remove_child(scene_camera)
		render.viewport.add_child(scene_camera)
		scene_camera.current = true
		var selection_menu : Node = preload("res://Menus/Selection Menu/SelectionMenu.tscn").instance()
		selection_menu.number_of_player = 1
		$SelectionMenus/HBoxContainer/VBoxContainer.add_child(selection_menu)
		selection_menus[0] = selection_menu
		var pause_menu : Node = preload("res://Menus/PauseMenu.tscn").instance()
		pause_menu.number_of_player = 1
		render.add_child(pause_menu)
		ProjectSettings.set("player1", new_players[0])
		ProjectSettings.set("scene_camera_1", scene_camera)
		#
		new_player.name = str(get_tree().get_network_unique_id())
		new_player.set_network_master(get_tree().get_network_unique_id())
		# add_child(new_player)
		var info = Network.self_data1
		new_player.init(info.name, info.position, false, info.health, false, false) # O info.is_alive, info.is_in_a_vehicle
	else:
		print("ERROR: No players")
		breakpoint
	
	if LocalMultiplayer.number_of_players >= 2:
		var new_player2 : Player = preload("res://Troops/Player/Player.tscn").instance()
		new_players[1] = new_player2
		var render2 = $Splitscreen.add_player(1)
		render2.viewport.msaa = get_tree().get_root().msaa
		new_players[1].number_of_player = 2
		render2.viewport.add_child(new_players[1])
		var scene_camera2 = $SceneCamera2 # CHANGE
		remove_child(scene_camera2)
		render2.viewport.add_child(scene_camera2)
		scene_camera2.current = true
		var pause_menu : Node = preload("res://Menus/PauseMenu.tscn").instance()
		pause_menu.number_of_player = 2
		render2.add_child(pause_menu)
		ProjectSettings.set("player2", new_players[1])
		ProjectSettings.set("scene_camera_2", scene_camera2)
		#
		new_player2.name = str(get_tree().get_network_unique_id())
		new_player2.set_network_master(get_tree().get_network_unique_id())
		# add_child(new_player2)
		var info = Network.self_data2
		new_player2.init(info.name, info.position, false, info.health, false, false)
	
	if LocalMultiplayer.number_of_players >= 3:
		var new_player3 : Player = preload("res://Troops/Player/Player.tscn").instance()
		new_players[2] = new_player3
		var render3 = $Splitscreen.add_player(2)
		render3.viewport.msaa = get_tree().get_root().msaa
		new_players[2].number_of_player = 3
		render3.viewport.add_child(new_players[2])
		var scene_camera3 = $SceneCamera3 # CHANGE
		remove_child(scene_camera3)
		render3.viewport.add_child(scene_camera3)
		scene_camera3.current = true
		var pause_menu : Node = preload("res://Menus/PauseMenu.tscn").instance()
		pause_menu.number_of_player = 3
		render3.add_child(pause_menu)
		ProjectSettings.set("player3", new_players[2])
		ProjectSettings.set("scene_camera_3", scene_camera3)
		var info = Network.self_data1
		new_player3.init(info.name, info.position, false, info.health, false, false)
	
	if LocalMultiplayer.number_of_players == 4:
		var new_player4 : Player = preload("res://Troops/Player/Player.tscn").instance()
		new_players[3] = new_player4
		var render4 = $Splitscreen.add_player(3)
		render4.viewport.msaa = get_tree().get_root().msaa
		new_players[3].number_of_player = 4
		render4.viewport.add_child(new_players[3])
		var scene_camera4 = $SceneCamera4 # CHANGE
		remove_child(scene_camera4)
		render4.viewport.add_child(scene_camera4)
		scene_camera4.current = true
		var pause_menu : Node = preload("res://Menus/PauseMenu.tscn").instance()
		pause_menu.number_of_player = 4
		render4.add_child(pause_menu)
		ProjectSettings.set("player4", new_players[3])
		ProjectSettings.set("scene_camera_4", scene_camera4)
		var info = Network.self_data1
		new_player4.init(info.name, info.position, false, info.health, false, false)
	
	if LocalMultiplayer.number_of_players == 2:
		var selection_menu : Node = preload("res://Menus/Selection Menu/SelectionMenu.tscn").instance()
		selection_menu.number_of_player = 2
		$SelectionMenus/HBoxContainer/VBoxContainer.add_child(selection_menu)
		selection_menus[1] = selection_menu
	elif LocalMultiplayer.number_of_players > 2:
		var selection_menu : Node = preload("res://Menus/Selection Menu/SelectionMenu.tscn").instance()
		selection_menu.number_of_player = 2
		$SelectionMenus/HBoxContainer/VBoxContainer2.show()
		$SelectionMenus/HBoxContainer/VBoxContainer2.add_child(selection_menu)
		selection_menus[1] = selection_menu
	if LocalMultiplayer.number_of_players >= 3:
		var selection_menu : Node = preload("res://Menus/Selection Menu/SelectionMenu.tscn").instance()
		selection_menu.number_of_player = 3
		$SelectionMenus/HBoxContainer/VBoxContainer.add_child(selection_menu)
		selection_menus[2] = selection_menu
	if LocalMultiplayer.number_of_players == 4:
		var selection_menu : Node = preload("res://Menus/Selection Menu/SelectionMenu.tscn").instance()
		selection_menu.number_of_player = 4
		$SelectionMenus/HBoxContainer/VBoxContainer2.add_child(selection_menu)
		selection_menus[3] = selection_menu
	
	if LocalMultiplayer.number_of_players == 3:
		enable_scene_camera4()
	
	if LocalMultiplayer.number_of_players > 1:
		for menu in selection_menus:
			if menu != null:
				menu.get_node("ClassMenu/VBoxContainer2").rect_scale = Vector2(0.5, 0.5)

	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			for vehicle in $Vehicles.get_children():
				vehicle.queue_free()
			
			for ship in $CapitalShips.get_children():
				ship.queue_free()
	
	Settings.apply_settings()
	# Pròximament
	# if Settings.controller_input:
	#	$PauseMenu/Menu/Settings/CheckButton.pressed = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
				
				if not vehicles_instantiated:
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
					vehicles_instantiated = true
				
				if not troops_instantiated:
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
					troops_instantiated = true
				
				if not capital_ships_instantiated:
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
					capital_ships_instantiated = true

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

func enable_scene_camera4() -> void:
	var render4 = $Splitscreen.add_player(3)
	render4.name = "IGNORE"
	render4.viewport.msaa = get_tree().get_root().msaa
	var scene_camera4 = $SceneCamera4 # CHANGE
	remove_child(scene_camera4)
	render4.viewport.add_child(scene_camera4)
	scene_camera4.current = true
	scene_camera4.translation = Vector3(0, 300, 0)
	scene_camera4.rotation = Vector3(deg2rad(-90), 0, 0)
	var new_node = Control.new()
	new_node.set_h_size_flags(new_node.SIZE_EXPAND_FILL)
	new_node.set_v_size_flags(new_node.SIZE_EXPAND_FILL)
	new_node.name = "Ignore"
	$SelectionMenus/HBoxContainer/VBoxContainer2.add_child(new_node)

func set_troop_material(new_troop : Troop) -> void:
	# Millorar
	if new_troop.get_node("TroopManager").m_team == 1:
		new_troop.get_node("MeshInstance").set_material_override(preload("res://Command Post/Blue.tres"))
	else:
		new_troop.get_node("MeshInstance").set_material_override(preload("res://Command Post/Red.tres"))

func add_new_player(number : int):
	pass
