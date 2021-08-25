extends "TroopState.gd"


func update(delta):
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	var gun = owner.get_node("Weapons/AIGun")
	gun.shooting = false # per no haver d'escriure en totes les excepcions "= false"
	
	if owner.current_enemie:
			if owner.current_enemie.has_node("TroopManager"):
				# Té TroopManager (comprov per si un cas)
				if owner.current_enemie.get_node("TroopManager").is_alive:
					# És viu
					owner.look_at(owner.current_enemie.global_transform.origin, Vector3(0, 1, 0))
					owner.rotation = Vector3(0, owner.rotation.y + deg2rad(180), 0)
					gun.shooting = true
				else:
					# És mort, treu-lo
					var enemies = owner.get_node("EnemyDetection").enemies
					for i in range(enemies.size()):
						if not enemies.size() > i: # if i > enemies.size -> no succeirà mai, em pens q es pot (i s'ha de) treure
							return
						if enemies[i] == owner.current_enemie:
							enemies.remove(i)
					owner.current_enemie = null
	else:
		var path_maker : Node = owner.get_node("PathMaker")
		if path_maker.navigation_node: # (comprov per si un cas, però no caldria)
			owner.look_at(path_maker.navigation_node.to_global(path_maker.end), Vector3(0, 1, 0))
			owner.rotation = Vector3(0, owner.rotation.y + deg2rad(180), 0)


func _on_PathMaker_arrived():
	return
