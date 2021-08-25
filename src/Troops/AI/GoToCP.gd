extends "OnFloor.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func enter():
	# Només rig si pot ésser, que l'escena PLayerMesh sigui ja sols el rig
	owner.get_node("PlayerMesh/rig/AnimationPlayer").play("Man_Run", -1, 0.7)
	
	# Cercar els CP enemics
	var enemy_command_posts := []
	for command_post in get_tree().get_nodes_in_group("CommandPosts"):
		if command_post.m_team != owner.get_node("TroopManager").m_team and command_post.capturable:
			enemy_command_posts.push_back(command_post)
	
	# Hi ha CP
	if enemy_command_posts:
		var nearest_command_post : CommandPost
		"""
		# NEAREST CP
		nearest_command_post = enemy_command_posts[0]
		for command_post in enemy_command_posts:
			var nearest_distance =  nearest_command_post.global_transform.origin.distance_to(translation)
			if command_post.global_transform.origin.distance_to(translation) <= nearest_distance:
				nearest_command_post = command_post
		"""
		
		# RANDOM CP
		nearest_command_post = enemy_command_posts[randi()%enemy_command_posts.size()]
		
		var begin : Vector3 = owner.translation 
		begin = owner.get_node("PathMaker").navigation_node.get_closest_point(begin)
		
		var end := Vector3.ZERO
		end.x = rand_range(nearest_command_post.translation.x - 7, nearest_command_post.translation.x + 7)
		end.z = rand_range(nearest_command_post.translation.z - 7, nearest_command_post.translation.z + 7)
		
		owner.get_node("PathMaker").update_path(begin, end)
		
	# No hi ha CP enemics
	else:
		emit_signal("finished", "ground_idle")


func _on_PathMaker_arrived():
	emit_signal("finished", "conquer")


func _on_animation_finished(anim_name):
	if anim_name == "Man_Run":
		owner.get_node("PlayerMesh/rig/AnimationPlayer").play("Man_Run", -1, 0.7)
