extends KinematicBody
class_name ShipBullet

export var damage := 100
export var bullet_velocity := 700.0

var direction : Vector3
var ship # : Ship

var _hit := false
var _time_alive := 7.0
var _old_translation : Vector3


func _process(delta : float) -> void:
	if not _old_translation:
		_old_translation = translation
	
	if _hit: # Per l'animació d'explosió
		return
	
	_time_alive -= delta
	if _time_alive < 0:
		queue_free()
	
	move_and_collide(delta * direction * bullet_velocity)
	
	var exclude : Array = []
	var wr = weakref(ship)
	if wr.get_ref():
		exclude.push_back(ship)
	
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(translation, _old_translation, exclude)
	
	if result:
		# Explosió, overlap_shpere()
		if result.collider.is_in_group("Ships"):
			var ship = result.collider # : Ship
			if get_tree().has_network_peer():
				if get_tree().is_network_server():
					ship.get_node("HealthSystem").rpc("take_damage", damage)
			else:
				ship.get_node("HealthSystem").take_damage(damage)
			
		elif result.collider.is_in_group("CapitalShipsColliders"):
			var frigate : CapitalShip = result.collider.get_node("../../../")
			if get_tree().has_network_peer():
				if get_tree().is_network_server():
					frigate.get_node("HealthSystem").rpc("take_damage", damage)
			else:
				frigate.get_node("HealthSystem").take_damage(damage)
		
		queue_free() # $AnimationPlayer.play("explode")
		_hit = true
	
	_old_translation = translation
