"""
La tropa es mou a un lloc aletaori, car no hi ha CPs enemics
"""
extends "OnFloor.gd"


func enter():
	# Només rig si pot ésser, que l'escena PLayerMesh sigui ja sols el rig
	owner.get_node("PlayerMesh/rig/AnimationPlayer").play("Man_Run", -1, 0.7)
	
	var begin : Vector3 = owner.get_node("PathMaker").navigation_node.get_closest_point(owner.translation)
	var end := Vector3(rand_range(-200, 200), 0, rand_range(-200, 200))
	owner.get_node("PathMaker").update_path(begin, end)


func _on_animation_finished(anim_name):
	if anim_name == "Man_Run":
		owner.get_node("PlayerMesh/rig/AnimationPlayer").play("Man_Run", -1, 0.7)
