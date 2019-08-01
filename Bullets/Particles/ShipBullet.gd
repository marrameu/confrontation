extends KinematicBody

export(int) var damage := 50
var time_alive := 5.0
var direction := Vector3()

export(float) var bullet_velocity := 700.0
var hit := false

var ship : Ship
var old_translation : Vector3

func _ready():
	old_translation = translation

func _process(delta):
	if hit:
		return # Per l'animació d'explosió
	
	time_alive -= delta
	if time_alive < 0:
		queue_free()
	
	move_and_collide(delta * direction * bullet_velocity)
	
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(translation, old_translation, [ship])
	
	if result:
		if result.collider.is_in_group("Ships"):
			if get_tree().has_network_peer():
				if get_tree().is_network_server():
					result.collider.get_node("HealthSystem").rpc("take_damage", damage)
			else:
				result.collider.get_node("HealthSystem").take_damage(damage)
			
		elif result.collider.get_node("../../../") != null:
			var parent = result.collider.get_node("../../../")
			if parent.is_in_group("CapitalShips"):
				if get_tree().has_network_peer():
					if get_tree().is_network_server():
						parent.get_node("HealthSystem").rpc("take_damage", damage)
				else:
					parent.get_node("HealthSystem").take_damage(damage)
		
		queue_free() # $AnimationPlayer.play("explode")
		hit = true
	
	old_translation = translation
