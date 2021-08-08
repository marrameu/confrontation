extends Spatial
class_name CapitalShip

export var team : int = 0

export var cap_ship_id : int = 0

func _process(delta : float) -> void:
	$Label.text = str($HealthSystem.shield) + "; " + str($HealthSystem.health) + " HP"


func _physics_process(delta):
	pass # translation += Vector3(10 * delta, 0, 10*delta) # issue 22904 (clossed, 4.0)


func _on_HealthSystem_die() -> void:
	$Alarm.play()
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	$DestructionTimer.start()


func _on_DestructionTimer_timeout() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			for child in get_children():
				if child.is_in_group("Troops") or is_in_group("Ships"): # o vehicle
					child.get_node("HealthSystem").rpc("take_damage", INF, true) # gradual
			rpc("_explode")
	else:
		for child in get_children():
			if child is Ship or child is Troop or child is Player: # o vehicle
				child.get_node("HealthSystem").take_damage(INF, true) # gradual
		_explode()


sync func _explode() -> void:
	# Anim 
	queue_free()


func _on_Area_body_entered(body):
	if body.is_in_group("Ships") or body.is_in_group("Troops"):
		if body.get_parent() == self:
			return
		body.get_parent().remove_child(body)
		add_child(body)
		# posició nuaas
		body.translation = to_local(body.translation)
		body.rotation -= rotation


func _on_Area_body_exited(body):
	pass
	"""
	if body.is_in_group("Ships") or body.is_in_group("Troops"):
		if body.get_parent() == self:
			remove_child(body)
			get_node()add_child(body)
			
	"""

