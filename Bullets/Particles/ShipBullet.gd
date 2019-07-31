extends KinematicBody

export(int) var damage := 50
var time_alive := 5.0
var direction := Vector3()

export(float) var bullet_velocity := 500.0
var hit := false

func _ready():
	pass

func _process(delta):
	if hit:
		return # for anim
	
	time_alive -= delta
	if time_alive < 0:
		queue_free()
	var col = move_and_collide(delta * direction * bullet_velocity)
	if col:
		if col.collider:
			if col.collider.is_in_group("Ships"):
				if get_tree().has_network_peer():
					if get_tree().is_network_server():
						col.collider.get_node("HealthSystem").rpc("take_damage", damage)
				else:
					col.collider.get_node("HealthSystem").take_damage(damage)
			elif col.collider.get_node("../../../") != null:
				var parent = col.collider.get_node("../../../")
				if parent.is_in_group("CapitalShips"):
					if get_tree().has_network_peer():
						if get_tree().is_network_server():
							parent.get_node("HealthSystem").rpc("take_damage", damage)
					else:
						parent.get_node("HealthSystem").take_damage(damage)
		$CollisionShape.disabled = true
		queue_free() # $AnimationPlayer.play("explode")
		hit = true
