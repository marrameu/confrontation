extends RigidBody

class_name Ship

var landing_areas := 0

var is_player := false
var player_name := "" # Player id
var number_of_player := 0
var state := 0
# 0 = Parado # 1 = Volando # 2 = Levantándose # 3 = Aparcando

# Networking
puppet var slave_state := 0
puppet var slave_position : Vector3
puppet var slave_rotation : Vector3

# Vfx
const explosion_scene : PackedScene = preload("res://Ship/Explosion.tscn")

var jump_action_name := "jump"

func _ready():
	slave_position = translation
	slave_rotation = rotation

func _process(delta : float) -> void:
	var input = $Input/Player
	var physics = $Physics
	var final_linear_input := Vector3(input.strafe, 0.0, input.throttle)
	var final_angular_input :=  Vector3(input.pitch, input.yaw, input.roll)
	physics.set_physics_input(final_linear_input, final_angular_input)
	
	if state == 1 and get_colliding_bodies().size() > 0:
		for body in get_colliding_bodies():
			if not body.is_in_group("Bullets"):
				$HealthSystem.take_damage(INF)
	
	if is_player and Input.is_key_pressed(KEY_K):
		if get_tree().has_network_peer():
			if is_network_master():
				$HealthSystem.take_damage(INF)
		else:
			$HealthSystem.take_damage(INF)
	
	if is_player and Input.is_action_just_pressed(jump_action_name):
		if get_tree().has_network_peer():
			if is_network_master():
				if state == 0:
					leave()
				elif state == 1 and landing_areas > 0:
					land()
		else:
			if state == 0:
				leave()
			elif state == 1 and landing_areas > 0:
				land()

func _physics_process(delta : float) -> void:
	if not get_tree().has_network_peer():
		return
	
	if is_player:
		set_network_master(int(player_name))
		if is_network_master():
			rset_unreliable("slave_position", translation)
			rset_unreliable("slave_rotation", rotation)
			rset_unreliable("slave_state", state)
		else:
			translation = slave_position
			rotation = slave_rotation
			state = slave_state

func leave() -> void:
	set_mode(RigidBody.MODE_RIGID)
	state = 2
	$LeaveTimer.start()

func _on_LeaveTimer_timeout():
	state = 1

func land():
	state = 3
	(get_node("Physics") as ShipPhysics).desired_linear_force = Vector3.ZERO
	(get_node("Physics") as ShipPhysics).desired_angular_force = Vector3.ZERO

func _on_HealthSystem_die():
	if is_player:
		var player : Player = ProjectSettings.get("player" + String(number_of_player))
		if player: # Per al online
			player.get_node("Interaction").exit_ship()
			player.get_node("HealthSystem").take_damage(INF)
	
	if get_tree().has_network_peer():
		rpc("die")
	else:
		die()

sync func die() -> void:
	var explosion : Particles = explosion_scene.instance()
	get_node("/root/Main").add_child(explosion)
	explosion.translation = translation
	queue_free()
