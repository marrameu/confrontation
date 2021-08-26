extends Node

var vehicle_data = { vehicle_res = "", vehicle_name = "", health = 0, is_player = false, player_id = 0, state = 0,
position = Vector3(), rotation = Vector3(), team = 0, parent_cap_ship_id = 0 }

func _ready() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			# vehicle_data.vehicle_name = owner.name
			
			if get_parent().is_in_group("Ships"):
				if get_parent().is_in_group("Transports"):
					vehicle_data.vehicle_res = "res://src/Ships/ShipTransport.tscn"
					vehicle_data.team = get_node("../Transport").m_team
				else:
					vehicle_data.vehicle_res = "res://src/Ships/Ship.tscn"
			
			if get_node("../../") is CapitalShip:
				vehicle_data.parent_cap_ship_id = get_node("../../").cap_ship_id
			else:
				vehicle_data.parent_cap_ship_id = 0

# func _request_data
func _physics_process(delta : float) -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			vehicle_data.is_player = get_parent().is_player
			vehicle_data.state = get_parent().state
			vehicle_data.position = get_parent().translation
			vehicle_data.rotation = get_parent().rotation
			vehicle_data.health = get_node("../HealthSystem").health
			if get_parent().is_player:
				vehicle_data.player_id = get_parent().player_id
