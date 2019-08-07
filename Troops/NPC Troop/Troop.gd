extends StaticBody

class_name Troop

# Atack
var current_enemie : Spatial

# State
# enum o millor consts amb numeros
var idle := false
var conquering := false

var nickname := "Troop"

# Networking
puppet var slave_position : = Vector3()
puppet var slave_rotation : = 0.0

# Client
func init() -> void:
	if get_node("TroopManager").is_alive:
		pass
		# if start_in_a_vehicle:
		#	disable_components(false)
	else:
		die()

func _ready() -> void:
	pass

func _process(delta):
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	# Rotate & Walk
	# Si ha acabado de caminar
	if $PathMaker.path.size() < 1:
		# Update Path: Command Posts
		# Buscar los CP enemigos
		var enemy_command_posts := []
		for command_post in get_node("/root/Main/CommandPosts").get_children():
			if command_post.m_team != $TroopManager.m_team and command_post.capturable:
				enemy_command_posts.push_back(command_post)
		# Si hay CP enemigos
		if enemy_command_posts.size() > 0:
			# Si no está conquistando un CP
			if not conquering:
				idle = false
				conquering = true
				# NEAREST CP
				var nearest_command_post = enemy_command_posts[0]
				for command_post in enemy_command_posts:
					var nearest_distance =  nearest_command_post.global_transform.origin.distance_to(translation)
					if command_post.global_transform.origin.distance_to(translation) <= nearest_distance:
						nearest_command_post = command_post
				#
				#RANDOM CP
				nearest_command_post = enemy_command_posts[randi()%enemy_command_posts.size()]
				#
				$PathMaker.begin = get_node("/root/Main/Map/Navigation").get_closest_point(get_translation())
				$PathMaker.end = Vector3(rand_range(nearest_command_post.translation.x - 5, nearest_command_post.translation.x + 5), 0, rand_range(nearest_command_post.translation.z - 5, nearest_command_post.translation.z + 5))
				$PathMaker._update_path()
			# Si está conquistando un CP y el temporizador no ha sido iniciado
			elif ($ConquestTimer as Timer).time_left == 0:
				idle = false
				$ConquestTimer.wait_time = rand_range(7.0, 13.0)
				($ConquestTimer as Timer).start()
		# Si no hay CP enemigos y no está yendo a algun sitio aleatorio
		elif not idle:
			idle = true
			$PathMaker.begin = get_node("/root/Main/Navigation").get_closest_point(get_translation())
			$PathMaker.end = Vector3(rand_range(-100, 100), 0, rand_range(-100, 100))
			$PathMaker._update_path()
	else:
		look_at($PathMaker.end, Vector3(0, 1, 0))
		rotation = Vector3(0, rotation.y, 0)
		idle = false
		if ($ConquestTimer as Timer).time_left == 0 and conquering and translation.distance_to($PathMaker.end) < 10:
			$ConquestTimer.wait_time = rand_range(7.0, 13.0)
			($ConquestTimer as Timer).start()
	
	# Shoot
	if current_enemie:
		if current_enemie.get_node("TroopManager"):
			if current_enemie.get_node("TroopManager").is_alive:
				look_at(current_enemie.translation, Vector3(0 , 1, 0))
				rotation = Vector3(0, rotation.y, 0)
				if not $Weapons/TroopGun.shooting:
					$Weapons/TroopGun.start_shooting()
				return
			else:
				# Si al morir el enemigo no se sale del area "exit area" (como el los CP) hay que sacarlo del array de otra forma, así:
				for i in range(0, $EnemyDetection.enemies.size()):
					if not $EnemyDetection.enemies.size() > i:
						return
					if $EnemyDetection.enemies[i] == current_enemie:
							$EnemyDetection.enemies.remove(i)
				current_enemie = null
	if $Weapons/TroopGun.shooting:
		$Weapons/TroopGun.stop_shooting()

func _physics_process(delta : float) -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rset_unreliable("slave_position", translation)
			rset_unreliable("slave_rotation", rotation.y)
		else:
			translation = slave_position
			rotation = Vector3(0, slave_rotation, 0)

func _on_HealthSystem_die() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			($RespawnTimer as Timer).start()
			rpc("die")
	else:
		($RespawnTimer as Timer).start()
		die()

func _on_RespawnTimer_timeout():
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("respawn")
	else:
		respawn()

sync func die() -> void:
	$TroopManager.is_alive = false
	set_process(false)
	$PathMaker.set_process(false)
	for child in get_children():
		if child.has_method("hide"):
			child.hide()
	$CollisionShape.disabled = true
	$PathMaker.path = []
	$EnemyDetection.enemies = []
	# Weapons
	for weapon in $Weapons.get_children():
		weapon.get_node("Timer").stop()
		weapon.shooting = false

sync func respawn() -> void:
	$TroopManager.is_alive = true
	var command_posts := []
	for command_post in get_node("/root/Main/CommandPosts").get_children():
		if command_post.m_team == $TroopManager.m_team:
			command_posts.push_back(command_post)
		if command_posts.size() < 1:
			# _on_HealthSystem_die()
			translation = Vector3(rand_range(-100, 100), 1.6515, rand_range(-100, 100))
		else:
			var pos = command_posts[randi()%command_posts.size()].translation
			translation = Vector3(pos.x, 1.6515, pos.z)
	set_process(true)
	$PathMaker.set_process(true)
	for child in get_children():
		if child.has_method("show"):
			child.show()
	$CollisionShape.disabled = false
	$HealthSystem.heal($HealthSystem.MAX_HEALTH)

func _on_ConquestTimer_timeout():
	conquering = false
