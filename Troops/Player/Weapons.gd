extends Spatial

# Multiplayer
var shoot_action_name := ""

func _process(delta : float) -> void:
	if shoot_action_name == "":
		if LocalMultiplayer.number_of_players == 1:
			shoot_action_name = "shoot"
		elif LocalMultiplayer.number_of_players > 1:
			shoot_action_name = get_node("../InputManager").input_map.shoot
