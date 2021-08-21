extends StaticBody

class_name Troop

# Materials
export var body : NodePath

# Atack
var current_enemie : Spatial


# States (State Machine)
var state := 0
enum States { 
	UNABLED,
	GROUND_IDLE,
	GOING_TO_CP_TO_CONQUER, 
	CONQUERING_A_CP, 
	SEARCHING_SHIP }

var space := false # canvia quan apareix, depenent del CP
var my_cap_ship : Spatial # cal?

 # terra i aire
var searching_ship := false

# terra
var idle := false
var going_to_cp_to_conquer := false
var conquering_a_cp := false

var nickname := "Troop"


# Online
onready var my_network = $TroopNetwork

# temproal -> moure al TroopNetwork
var wait_a_fcking_moment := false
var wait_to_init := true


# Client
func init() -> void:
	if $TroopManager.is_alive:
		pass
		# if start_in_a_vehicle:
		#	disable_components(false)
	else:
		die()


func _physics_process(delta : float) -> void:
	my_network.update_my_data()


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
	#nse q es neceesari i q no, a més, moltes coses el client no les haruia de fer
	going_to_cp_to_conquer = false
	conquering_a_cp = false
	idle = false
	space = false
	searching_ship = false
	my_cap_ship = null
	$PathMaker.navigation_node = null
	$ConquestTimer.stop()
	
	$TroopManager.is_alive = false
	
	set_process(false)
	$PathMaker.set_process(false)
	
	$PathMaker.clean_path()
	$EnemyDetection.enemies = []
	
	for child in get_children():
		if child.has_method("hide"):
			child.hide()
	
	$CollisionShape.disabled = true
	
	# Weapons
	for weapon in $Weapons.get_children():
		weapon.shooting = false


sync func respawn() -> void:
	# canviar el parent
	$TroopManager.is_alive = true
	$PathMaker.clean_path()
	
	$CollisionShape.disabled = false
	
	var cp: CommandPost
	
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			var command_posts := []
			for command_post in get_tree().get_nodes_in_group("CommandPosts"):
				if command_post.m_team == $TroopManager.m_team:
					command_posts.push_back(command_post)
				if command_posts.size() < 1:
					# _on_HealthSystem_die()
					global_transform.origin = Vector3(rand_range(-100, 100), 1.6515, rand_range(-100, 100))
				else:
					cp = command_posts[randi()%command_posts.size()]
					global_transform.origin = cp.global_transform.origin #1,815
			
			space = global_transform.origin.y > 1000 # millor fer-ho depenent del CP
			if space:
				cp.get_node("../../").rpc("add_fill", get_path())
	else:
		var command_posts := []
		for command_post in get_tree().get_nodes_in_group("CommandPosts"):
			if command_post.m_team == $TroopManager.m_team:
				command_posts.push_back(command_post)
			if command_posts.size() < 1:
				# _on_HealthSystem_die()
				global_transform.origin = Vector3(rand_range(-100, 100), 1.6515, rand_range(-100, 100))
			else:
				cp = command_posts[randi()%command_posts.size()]
				global_transform.origin = cp.global_transform.origin #1,815
		
		space = global_transform.origin.y > 1000 # millor fer-ho depenent del CP
		if space:
			cp.get_node("../../").add_fill(get_path())
	
	set_process(true)
	$PathMaker.set_process(true)
	
	for child in get_children():
		if child.has_method("show"):
			child.show()
	
	$HealthSystem.heal($HealthSystem.MAX_HEALTH)


func set_material() -> void:
	if get_node("TroopManager").m_team == get_node("/root/Main").local_players[0].get_node("TroopManager").m_team:
		get_node(body).set_surface_material(2, load("res://assets/models/mannequiny/Azul_R.material"))
	else:
		get_node(body).set_surface_material(4, load("res://assets/models/mannequiny/Azul_L.material"))

