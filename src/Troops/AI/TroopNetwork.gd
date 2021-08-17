extends Node

onready var troop: Spatial = get_parent() # Com referencia l'StateMachine?

var troop_data = { name = "", troop_class = 0, position = Vector3(), rotation = Vector3(),
health = 0, is_alive = false, team = 0, is_in_a_vehicle = false, parent_cap_ship_id = 0 }

puppet var slave_position : = Vector3()
puppet var slave_rotation : = 0.0


func _ready() -> void:
	# Es fa al ready en lloc de al _physsics_process perquè només cal establir una vegada l'equip i el nom
	# Dubto que açò causi cap problema
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			troop_data.team = troop.get_node("TroopManager").m_team
			troop_data.name = troop.name


# func _request_data
func update_my_data() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			troop_data.position = troop.translation
			troop_data.rotation = troop.rotation
			troop_data.health = troop.get_node("HealthSystem").health
			troop_data.is_alive = troop.get_node("TroopManager").is_alive
			if troop.get_parent() is CapitalShip:
				troop_data.parent_cap_ship_id = troop.get_parent().cap_ship_id
			else:
				troop_data.parent_cap_ship_id = 0
	
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rset_unreliable("slave_position", troop.global_transform.origin)
			rset_unreliable("slave_rotation", troop.rotation.y)
		else:
			troop.global_transform.origin = slave_position
			troop.rotation = Vector3(0, slave_rotation, 0)

