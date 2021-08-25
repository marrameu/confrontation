extends Node

var attacking := false

# Multiplayer
var shoot_action := ""


func _process(delta : float) -> void:
	if shoot_action == "":
		shoot_action = "shoot" if LocalMultiplayer.number_of_players == 1 else get_node("../InputManager").input_map.shoot
