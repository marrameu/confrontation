extends StaticBody

class_name Troop

# Materials
export var BODY : NodePath

# Atack
var current_enemie : Spatial

var space := false # canvia quan apareix, depenent del CP
var my_cap_ship : Spatial = null # cal?

var nickname := "Tropa"

# Online
onready var my_network = $TroopNetwork

# temproal
var wait_a_fcking_moment := false


# Client
func init() -> void:
	if $TroopManager.is_alive:
		pass
		# if start_in_a_vehicle:
		#	disable_components(false)
	else:
		set_dead(true)


func _physics_process(delta : float) -> void:
	my_network.update_my_data()


func _on_HealthSystem_die() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			($RespawnTimer as Timer).start()
			rpc("set_dead", true)
	else:
		($RespawnTimer as Timer).start()
		set_dead(true)


func _on_RespawnTimer_timeout():
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("respawn")
	else:
		respawn()


# Moltes coses el client no les haruia de fer
sync func set_dead(value) -> void: # Canviar-li el nom a disable components per als vehicles o fer una funció a part?
	# NO -> my_cap_ship = null, només canviar-ho quan li canviem el parent(), si no errors online
	
	set_process(!value) # No caldria
	
	$TroopManager.is_alive = !value
	$PathMaker.clean_path()
	$EnemyDetection.set_active(!value)
	$CollisionShape.disabled = value
	
	visible = !value
	
	for weapon in $Weapons.get_children():
		weapon.shooting = false # ONLINE!?
	
	$StateMachine.set_active(!value) # s'ha de fer com a última cosa


sync func respawn() -> void:
	# Primer de tot s'estableix la posició, car, si no, la StateMachine no agafaria la posició bé
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			set_spawn_place()
	else:
		set_spawn_place()
	
	set_dead(false)
	$HealthSystem.heal($HealthSystem.MAX_HEALTH)


func set_spawn_place():
	var my_cp: CommandPost
	
	# Posició
	var command_posts := []
	for cp in get_tree().get_nodes_in_group("CommandPosts"):
		if cp.m_team == $TroopManager.m_team:
			command_posts.push_back(cp)
	if not command_posts:
		# _on_HealthSystem_die()
		global_transform.origin = Vector3(rand_range(-100, 100), 2, rand_range(-100, 100))
	else:
		my_cp = command_posts[randi()%command_posts.size()]
		global_transform.origin = my_cp.global_transform.origin #1,815
	
	# Naus capitals, codi MOLT MILLORABLE
	space = global_transform.origin.y > 1000 # millor fer-ho depenent del my_cp
	if space:
		if get_tree().has_network_peer():
			if my_cp.owner is CapitalShip:
				my_cp.owner.rpc("add_fill", get_path())
			elif my_cp.owner is Ship: # Transport
				my_cp.owner.get_parent().rpc("add_fill", get_path())
		else:
			if my_cp.owner is CapitalShip:
				my_cp.owner.add_fill(get_path())
			elif my_cp.owner is Ship: # Transport
				my_cp.owner.get_parent().add_fill(get_path())


func set_material() -> void:
	if get_node("TroopManager").m_team == get_node("/root/Main").local_players[0].get_node("TroopManager").m_team:
		get_node(BODY).set_surface_material(2, load("res://assets/models/mannequiny/Azul_R.material"))
	else:
		get_node(BODY).set_surface_material(4, load("res://assets/models/mannequiny/Azul_L.material"))

