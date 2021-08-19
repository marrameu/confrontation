extends "TroopState.gd"


func update(delta):
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	var gun = owner.get_node("Weapons/AIGun")
	if owner.current_enemie:
			if owner.current_enemie.has_node("TroopManager"):
				if owner.current_enemie.get_node("TroopManager").is_alive:
					owner.look_at(owner.current_enemie.global_transform.origin, Vector3(0, 1, 0))
					owner.rotation = Vector3(0, owner.rotation.y + deg2rad(180), 0)
					if not gun.shooting:
						gun.shooting = true
					return
				else:
					var enemies = owner.get_node("EnemyDetection").enemies
					for i in range(0, enemies.size()):
						if not enemies.size() > i:
							return
						if enemies[i] == owner.current_enemie:
							enemies.remove(i)
					owner.current_enemie = null
	gun.shooting = false
