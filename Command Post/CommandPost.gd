extends Spatial

class_name CommandPost

export(bool) var capturable := true
export(int) var start_team := 0

var materials := {
	0: preload("res://Command Post/Grey.tres"),
	1: preload("res://Command Post/Blue.tres"),
	2: preload("res://Command Post/Red.tres"),
	3: preload("res://Command Post/Yellow.tres")
}
var team_count := [0.0, 0.0, 0.0]
var m_team : int = 0
var bodies := [0, 0, 0]

var old_menus := []
var buttons := []

puppet var slave_team_count := [0.0, 0.0, 0.0]

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
		if old_menus[i].get_node("SpawnMenu").visible and not (ProjectSettings.get("scene_camera_" + String(old_menus[i].number_of_player)) as Camera).is_position_behind(translation):
			buttons[i].show()
			buttons[i].rect_position = (ProjectSettings.get("scene_camera_" + String(old_menus[i].number_of_player)) as Camera).unproject_position(translation) - Vector2(buttons[i].rect_size.x / 2, buttons[i].rect_size.y / 2)
			update_button_color(buttons[i])
		else:
			buttons[i].hide()
	
	if not capturable:
		return
	
	bodies[0] = 0
	bodies[1] = 0
	bodies[2] = 0
	for body in $Area.get_overlapping_bodies():
		if body.is_in_group("Players") or body.is_in_group("Troops"):
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
	
	$HBoxContainer/Team1.text = str(team_count[0])
	$HBoxContainer/Team2.text = str(team_count[1])
	$HBoxContainer/Team3.text = str(team_count[2])
	
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

func _on_Area_body_entered(body : CollisionObject) -> void:
	if body.is_in_group("Players") and capturable:
		$HBoxContainer.show()

func _on_Area_body_exited(body : CollisionObject) -> void:
	if body.is_in_group("Players") and capturable:
		$HBoxContainer.hide()

func update_button_color(button : Button) -> void:
	if m_team == 0:
		button.add_color_override("font_color", Color.white)
		#PLAYER 111
	elif m_team == ProjectSettings.get("player1").get_node("TroopManager").m_team:
		button.add_color_override("font_color", Color("b4c7dc"))
	else:
		button.add_color_override("font_color", Color("dcb4b4"))

func update_menus() -> void:
	var new_menus := []
	
	for child in get_node("/root/Main/SelectionMenus/HBoxContainer").get_children():
		for menu in child.get_children():
			if menu.name != "Ignore":
				new_menus.push_back(menu)
	
	var menus_to_remove := []
	
	for i in range(0, new_menus.size()):
		for old_menu in old_menus:
			if new_menus[i] == old_menu:
				menus_to_remove.push_back(i)
	
	var a := 0
	for i in range(0, menus_to_remove.size()):
		new_menus.remove(menus_to_remove[i - a])
		a += 1
	
	for new_menu in new_menus:
		old_menus.push_back(new_menu)
		
		var button : Button = $Button.duplicate(1)
		remove_child(button)
		new_menu.get_node("SpawnMenu/Buttons").add_child(button)
		button.connect("pressed", new_menu, "_on_CommandPostButton_pressed", [self])
		connect("tree_exiting", button, "queue_free")
		buttons.push_back(button)

func update_material() -> void:
	if ProjectSettings.get("player1") == null:
		return
	
	var player_team : int = ProjectSettings.get("player1").get_node("TroopManager").m_team
	if m_team == 0:
		$MeshInstance.set_material_override(materials[0])
	elif m_team == 3:
		$MeshInstance.set_material_override(materials[3])
	elif m_team == player_team:
		$MeshInstance.set_material_override(materials[1])
	elif m_team != player_team:
		$MeshInstance.set_material_override(materials[2])
