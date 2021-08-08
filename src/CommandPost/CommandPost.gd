extends Spatial

class_name CommandPost

export var capturable := true
export(int, 0, 2) var start_team := 0

const materials := {
	0: preload("res://assets/materials/command_post/grey.tres"),
	1: preload("res://assets/materials/command_post/blue.tres"),
	2: preload("res://assets/materials/command_post/red.tres"),
	3: preload("res://assets/materials/command_post/yellow.tres")
}
var team_count := [0.0, 0.0, 0.0]
var m_team : int = 0
var bodies : PoolIntArray = [0, 0, 0]

var old_menus := []
var buttons := []

puppet var slave_team_count := [0.0, 0.0, 0.0]

var is_ground : bool = false


func _ready() -> void:
	if start_team == 1:
		team_count[0] = 10
	elif start_team == 2:
		team_count[1] = 10
	elif start_team == 3:
		team_count[2] = 10


func _process(delta : float) -> void:
	update_menus()
	
	for i in range(0, old_menus.size()):
		var scene_camera : Camera = get_node("/root/Main").players_cameras[old_menus[i].get_parent().number_of_player - 1].scene_camera
		
		if old_menus[i].get_node("SpawnMenu").visible and not scene_camera.is_position_behind(global_transform.origin):
			buttons[i].rect_position = scene_camera.unproject_position(global_transform.origin)
			# Mirar si es pot treure
			buttons[i].rect_position -= Vector2(buttons[i].rect_size.x / 2, buttons[i].rect_size.y / 2)
			
			# Millorar
			if LocalMultiplayer.number_of_players > 1:
				buttons[i].rect_position.y *= 2
				buttons[i].rect_position.x *= 2
				if LocalMultiplayer.number_of_players == 2:
					buttons[i].rect_position.x -= 480 * 2
				else:
					buttons[i].rect_position.x += 240
			
			update_button_color(buttons[i])
			buttons[i].show()
		else:
			buttons[i].hide()
	
	if not capturable:
		return
	
	bodies[0] = 0
	bodies[1] = 0
	bodies[2] = 0
	for body in $Area.get_overlapping_bodies():
		if body.is_in_group("Troops"):
			var troop_manager : Node = body.get_node("TroopManager")
			if troop_manager:
				var health_system : Node = body.get_node("HealthSystem")
				if health_system.health > 0:
					if troop_manager.m_team == 1:
						bodies[0] += 1
					elif troop_manager.m_team == 2:
						bodies[1] += 1
					elif troop_manager.m_team == 3:
						bodies[2] += 1


func _physics_process(delta : float) -> void:
	if not capturable:
		return
	
	if team_count[0] > 7 and m_team != 1:
		m_team = 1
	elif team_count[1] > 7 and m_team != 2:
		m_team = 2
	elif team_count[2] > 7 and m_team != 3:
		m_team = 3
	elif team_count[0] + team_count[1] + team_count[2] < 7:
		m_team = 0
	
	update_material()
	
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rset_unreliable("slave_team_count", team_count)
		else:
			team_count = slave_team_count
			return
	
	# Sphagetti Code
	if bodies[0] > 0 and bodies[1] + bodies[2] == 0:
		# Team 1 Conquering
		if team_count[1] + team_count[2] > 0:
			team_count[1] = clamp(team_count[1] - delta * bodies[0], 0, 10)
			team_count[2] = clamp(team_count[2] - delta * bodies[0], 0, 10)
		else:
			team_count[0] = clamp(team_count[0] + delta * bodies[0], 0, 10)
		
	elif bodies[1] > 0 and bodies[0] + bodies[2] == 0:
		# Team 2 Conquering
		if team_count[0] + team_count[2] > 0:
			team_count[0] = clamp(team_count[0] - delta * bodies[1], 0, 10)
			team_count[2] = clamp(team_count[2] - delta * bodies[1], 0, 10)
		else:
			team_count[1] = clamp(team_count[1] + delta * bodies[1], 0, 10)
		
	elif bodies[2] > 0 and bodies[0] + bodies[1] == 0:
		# Team 3 Conquering
		if team_count[0] + team_count[1] > 0:
			team_count[0] = clamp(team_count[0] - delta * bodies[2], 0, 10)
			team_count[1] = clamp(team_count[1] - delta * bodies[2], 0, 10)
		else:
			team_count[2] = clamp(team_count[2] + delta * bodies[2], 0, 10)


func update_button_color(button : Button) -> void:
	if m_team == 0:
		button.add_color_override("font_color", Color.white)
	elif m_team == get_node("/root/Main").local_players[0].get_node("TroopManager").m_team:
		button.add_color_override("font_color", Color("b4c7dc"))
	else:
		button.add_color_override("font_color", Color("dcb4b4"))

func update_menus() -> void:
	var new_menus := []
	
	for child in get_node("/root/Main/SelectionMenus").get_children():
		for menu in child.get_children():
			new_menus.push_back(menu)
	
	var menus_to_remove := []
	
	for i in range(0, new_menus.size()):
		for old_menu in old_menus:
			if new_menus[i] == old_menu:
				menus_to_remove.push_back(i)
	
	var elements_removed := 0
	for i in range(0, menus_to_remove.size()):
		new_menus.remove(menus_to_remove[i - elements_removed])
		elements_removed += 1
	
	for new_menu in new_menus:
		old_menus.push_back(new_menu)
		
		var button : Button = load("res://src/CommandPost/CPButton.tscn").instance()
		new_menu.get_node("SpawnMenu/Buttons").add_child(button)
		button.connect("pressed", new_menu.get_parent(), "_on_CommandPostButton_pressed", [self])
		connect("tree_exiting", button, "queue_free")
		buttons.push_back(button)


func update_material() -> void:
	if not get_node("/root/Main").local_players[0]:
		return
	
	var player_team : int = get_node("/root/Main").local_players[0].get_node("TroopManager").m_team
	if m_team == 0:
		$MeshInstance.set_material_override(materials[0])
	elif m_team == 3:
		$MeshInstance.set_material_override(materials[3])
	elif m_team == player_team:
		$MeshInstance.set_material_override(materials[1])
	elif m_team != player_team:
		$MeshInstance.set_material_override(materials[2])
