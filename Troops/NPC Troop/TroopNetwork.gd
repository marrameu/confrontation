extends Node

var troop_data = { name = "", troop_class = 0, position = Vector3(), rotation = Vector3(),
health = 0, is_alive = false, team = 0, is_in_a_vehicle = false }

func _ready() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			troop_data.team = get_node("../TroopManager").m_team

# func _request_data
func _physics_process(delta : float) -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			troop_data.name = get_parent().name
			troop_data.position = get_parent().translation
			troop_data.rotation = get_parent().rotation
			troop_data.health = get_node("../HealthSystem").health
			troop_data.is_alive = get_node("../TroopManager").is_alive
