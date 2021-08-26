extends RigidBody
class_name Ship

enum State { LANDED, FLYING, LEAVING, LANDING }

var landing_areas := 0

var is_player := false
var player_id := 0 # Player ID
var number_of_player := 0
var state := 0

var is_ai := false

puppet var slave_state := 0
puppet var slave_position : Vector3
puppet var slave_rotation : Vector3

const explosion_scene : PackedScene = preload("res://src/Ships/Explosion/Explosion.tscn")

var jump_action := "jump"

var input : Node # class per al input

# temproal
var wait_a_fcking_moment := false


func _ready():
	# nom aletaori si es server
	slave_position = global_transform.origin # cal fer-ho perquè si no quan el jugador hi entra hi ha un frame que la nau apareix a 0, 0 i per tant es com si sortís de la CS
	slave_rotation = global_transform.basis.get_euler()


func _process(delta : float) -> void:
	# no cal fer tot açò si no ets server
	# match
	if not input: # s'ha de desassignar, llavors; o fer-ho per senyals
		if is_player:
			input = $Input/Player # export var
		elif is_ai:
			input = $Input/AI
		else:
			return
	
	var final_linear_input := Vector3(input.strafe, 0.0, input.throttle)
	var final_angular_input :=  Vector3(input.pitch, input.yaw, input.roll)
	$Physics.set_physics_input(final_linear_input, final_angular_input)
	
	# Coŀlideix i mor
	if state == State.FLYING and get_colliding_bodies().size() > 0:
		for body in get_colliding_bodies():
			if not body.is_in_group("Bullets"):
				if get_tree().has_network_peer():
					if is_network_master():
						$HealthSystem.rpc("take_damage", INF, true)
				else:
					$HealthSystem.take_damage(INF, true)
	
	# Prem la K
	if is_player and Input.is_key_pressed(KEY_K): # en un scrit propi per senyals
		if get_tree().has_network_peer():
			if is_network_master():
				$HealthSystem.rpc("take_damage", INF, true)
		else:
			$HealthSystem.take_damage(INF, true)
	
	if is_player and Input.is_action_just_pressed(jump_action): # en un scrit propi per senyals
		if get_tree().has_network_peer():
			if is_network_master():
				if state == State.LANDED:
					leave()
				elif state == State.FLYING and landing_areas > 0:
					land()
		else:
			if state == State.LANDED:
				leave()
			elif state == State.FLYING and landing_areas > 0:
				land()


func _physics_process(delta : float) -> void:
	if not get_tree().has_network_peer():
		return
	
	if is_player:
		set_network_master(player_id) #si és 0, doncs no en té
		if is_network_master():
			rset_unreliable("slave_position", global_transform.origin)
			rset_unreliable("slave_rotation", global_transform.basis.get_euler())
			rset_unreliable("slave_state", state)
		else:
			global_transform.origin = slave_position
			global_transform.basis = slave_rotation
			state = slave_state


func leave() -> void:
	set_mode(RigidBody.MODE_RIGID)
	state = State.LEAVING
	$LeaveTimer.start()


func _on_LeaveTimer_timeout():
	state = State.FLYING


func land():
	state = State.LANDING
	get_node("Physics").desired_linear_force = Vector3()
	get_node("Physics").desired_angular_force = Vector3()


# S'executa a totes les instàncies, car el take_damage() és sync
func _on_HealthSystem_die():
	if is_player:
		var player : Player = get_node("/root/Main").local_players[number_of_player - 1]
		if player: # Per al online, si es desconecta i està en una nau
			player.get_node("Interaction").exit_ship()
			player.get_node("HealthSystem").take_damage(INF, true)
	
	# Cal fer això abans del queue_free(), car, altrament, com que el queue_free()
	# eliminaria la nau de l'arbre, s'executaria un rpc per al remove_fill(),
	# però com que ja no hi és es faria un emboilc de cal Déu
	
	if get_parent().is_in_group("CapitalShips"):
		if get_tree().has_network_peer():
			if get_tree().is_network_server():
				get_parent().rpc("remove_passatger", get_path())
		else:
			get_parent().remove_passatger(get_path())
	
	if get_tree().has_network_peer():
		rpc("die")
	else:
		die()


sync func die() -> void:
	var explosion : Particles = explosion_scene.instance()
	get_node("/root/Main").add_child(explosion)
	explosion.translation = global_transform.origin
	
	queue_free()
