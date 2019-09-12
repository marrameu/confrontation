extends "res://src/HealthSystem/HealthSystem.gd"


func _on_HealthSystem_die() -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			get_node("../RespawnTimer").start()
	else:
		get_node("../RespawnTimer").start()
	
	if get_tree().has_network_peer():
		rpc("die")
	else:
		die()


func _on_RespawnTimer_timeout() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var selection_menu : SelectionMenu = get_node("/root/Main").selection_menus[get_parent().number_of_player - 1]
	var spawn_menu = selection_menu.get_node("Container/SpawnMenu")
	spawn_menu.get_node("SpawnButton").hide()
	spawn_menu.show()
	
	# get_node("/root/Main/CommandPosts").get_child(0).buttons[number_of_player - 1].grab_focus()


sync func die() -> void:
	health = 0 # Per al HUD (temporal)
	get_node("../TroopManager").is_alive = false
	
	if get_tree().has_network_peer(): # Per al mode un jugador
		if is_network_master():
			get_parent().update_network_info()
	
	update_components(false)
	
	var scene_camera : Camera = get_node("/root/Main").players_cameras[get_parent().number_of_player - 1].scene_camera
	if scene_camera:
		if get_tree().has_network_peer():
			if is_network_master():
				scene_camera.make_current()
		else:
			scene_camera.make_current()


sync func respawn() -> void:
	get_node("../TroopManager").is_alive = true
	
	var command_posts := []
	for command_post in get_node("/root/Main/CommandPosts").get_children():
		if command_post.m_team == get_node("../TroopManager").m_team:
			command_posts.push_back(command_post)
		if command_posts.size() < 1:
			# No hi han cps del teu equip
			get_parent().translation = Vector3(rand_range(-200, 200), 2, rand_range(-200, 200))
		else:
			get_parent().translation = get_parent().spawn_position
	
	get_parent().rotation = Vector3()
	
	update_components(true)
	
	var scene_camera : Camera = get_node("/root/Main").players_cameras[get_parent().number_of_player - 1].scene_camera
	if scene_camera:
		if get_tree().has_network_peer():
			if is_network_master():
				scene_camera.clear_current()
		else:
			scene_camera.clear_current()
	
	heal(MAX_HEALTH)


func update_components(var enable : bool, var update_interaction := true) -> void:
	get_parent().set_process(enable)
	get_parent().set_physics_process(enable)
	
	get_node("../StateMachine/Movement/Move").velocity = Vector3()
	
	if get_node("../Crouch").crouching:
		get_node("../Crouch").get_up()
	get_node("../Crouch").set_process(enable)
	get_node("../CameraBase").set_process(enable)
	
	if update_interaction:
		get_node("../Interaction").set_process(enable)
	
	get_node("../CollisionShape").disabled = !enable
	
	for weapon in get_node("../Weapons").get_children():
		weapon.shooting = false
		weapon.set_process(enable)
		
		var weapon_hud = weapon.get_node("HUD")
		if weapon_hud:
			for child in weapon_hud.get_children():
				if child is Control:
					child.visible = enable
	
	for child in get_parent().get_children():
		if child is Spatial:
			child.visible = enable
	
	if get_tree().has_network_peer():
		if not is_network_master():
			return
	
	get_node("../CameraBase/Camera").current = enable
	get_node("../Listener").current = enable
