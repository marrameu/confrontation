extends Node

var crounching := false
onready var capsule_mesh := get_parent().get_node("MeshInstance") 
onready var capsule_collision := get_parent().get_node("CollisionShape") 

# Multiplayer
var action_name := ""

func _ready() -> void:
	capsule_mesh.mesh = capsule_mesh.mesh.duplicate()
	capsule_collision.shape = capsule_collision.shape.duplicate()

func _process(delta : float) -> void:
	if action_name == "":
		if LocalMultiplayer.number_of_players == 1:
			action_name = "crounch"
		elif LocalMultiplayer.number_of_players > 1:
			action_name = get_node("../InputManager").input_map.crounch
	
	if Input.is_action_just_pressed(action_name):
		if not crounching:
			if get_tree().has_network_peer():
				if is_network_master():
					rpc("crounch")
			else:
				crounch()
		else:
			if get_tree().has_network_peer():
				if is_network_master():
					rpc("get_up")
			else:
				get_up()

sync func crounch():
	crounching = true
	capsule_mesh.mesh.set_mid_height(1.5)
	capsule_collision.translation += Vector3(0, -0.15, 0)
	capsule_collision.shape.set_height(1.5)
	capsule_mesh.translation += Vector3(0, -0.15, 0)

sync func get_up():
	crounching = false
	capsule_mesh.mesh.set_mid_height(1.8)
	capsule_collision.translation += Vector3(0, 0.15, 0)
	capsule_collision.shape.set_height(1.8)
	capsule_mesh.translation += Vector3(0, 0.15, 0)
