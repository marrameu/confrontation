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
	if get_tree().has_network_peer():
		rpc("disable_components", true)
	else:
		disable_components(true)
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
			# No hay más CP de tu equipo
			get_parent().translation = Vector3(rand_range(-200, 200), 2, rand_range(-200, 200))
		else:
			get_parent().translation = get_parent().spawn_position
	get_parent().rotation = Vector3()
	if get_tree().has_network_peer():
		rpc("enable_components", true)
	else:
		enable_components(true)
	var scene_camera : Camera = get_node("/root/Main").players_cameras[get_parent().number_of_player - 1].scene_camera
	if scene_camera:
		if get_tree().has_network_peer():
			if is_network_master():
				scene_camera.clear_current()
		else:
			scene_camera.clear_current()
	heal(MAX_HEALTH)


# DISABLE I ENABLE ES PODEN FER EN NOMÉS UNA FUNCIÓ
sync func disable_components(var disable_interaction : bool) -> void:
	get_parent().set_physics_process(false)
	get_parent().set_process(false)
	get_node("../StateMachine/Movement/Move").velocity = Vector3()
	if get_node("../Crouch").crouching:
		get_node("../Crouch").get_up()
	get_node("../Crouch").set_process(false)
	get_node("../CameraBase").set_process(false)
	if disable_interaction:
		get_node("../Interaction").set_process(false)
	for weapon in get_node("../Weapons").get_children():
		weapon.shooting = false
		weapon.set_process(false)
		#HUD
		var weapon_hud = weapon.get_node("HUD")
		if weapon_hud:
			for child in weapon_hud.get_children():
				if child.has_method("hide"):
					child.hide()
	for child in get_parent().get_children():
		if child.has_method("hide"):
			child.hide()
	get_node("../CollisionShape").disabled = true
	if get_tree().has_network_peer():
		if is_network_master():
			get_node("../CameraBase/Camera").clear_current()
			get_node("../Listener").clear_current()
	else:
		get_node("../CameraBase/Camera").clear_current()
		get_node("../Listener").clear_current()


sync func enable_components(var enable_interaction : bool) -> void:
	get_parent().set_physics_process(true)
	get_parent().set_process(true)
	get_node("../Crouch").set_process(false)
	get_node("../CameraBase").set_process(true)
	if enable_interaction:
		get_node("../Interaction").set_process(true)
	for weapon in get_node("../Weapons").get_children():
		weapon.set_process(true)
		#HUD
		var weapon_hud = weapon.get_node("HUD")
		if weapon_hud:
			for child in weapon_hud.get_children():
				if child.has_method("show"):
					child.show()
	for child in get_parent().get_children():
		if child.has_method("show"):
			child.show()
	get_node("../CollisionShape").disabled = false
	if get_tree().has_network_peer():
		if is_network_master():
			get_node("../CameraBase/Camera").make_current()
			get_node("../Listener").make_current()
	else:
		get_node("../CameraBase/Camera").make_current()
		get_node("../Listener").make_current()
