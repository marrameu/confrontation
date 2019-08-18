extends Node

var crouching := false
onready var capsule_collision := get_parent().get_node("CollisionShape") 

# Multiplayer
var action := ""

func _ready() -> void:
	capsule_collision.shape = capsule_collision.shape.duplicate()

func _process(delta : float) -> void:
	if action == "":
		action = "crouch" if LocalMultiplayer.number_of_players == 1 else get_node("../InputManager").input_map.crouch
	
	if Input.is_action_just_pressed(action):
		if not crouching:
			if get_tree().has_network_peer():
				if is_network_master():
					rpc("crouch")
			else:
				crouch()
		else:
			if get_tree().has_network_peer():
				if is_network_master():
					rpc("get_up")
			else:
				get_up()

sync func crouch():
	crouching = true
	# Anim
	capsule_collision.translation += Vector3(0, -0.25, 0)
	capsule_collision.shape.set_height(1.9)

sync func get_up():
	crouching = false
	# Anim
	capsule_collision.translation += Vector3(0, 0.25, 0)
	capsule_collision.shape.set_height(2.4)
