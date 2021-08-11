extends Spatial
class_name CapitalShip

export var team : int = 0

export var cap_ship_id : int = 0


func _ready():
	$Hangar/Area.connect("body_entered", self, "_on_Area_body_entered", [])
	$Hangar/Area.connect("body_exited", self, "_on_Area_body_exited", [])


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
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("add_passatger", body)
	else:
		add_passatger(body)


func _on_Area_body_exited(body):
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("remove_passatger", body)
	else:
		remove_passatger(body)


sync func add_passatger(body):
	if body.get_parent() == self: # per a les naus que hi són des del principi
		return
	if body.is_in_group("Ships") or body.is_in_group("Troops"):
		
		if body.wait_a_fcking_moment:
			return
		
		print("entra a " + name + " " + body.name)
		
		# issuea 14578
		body.wait_a_fcking_moment = true
		body.get_parent().remove_child(body)
		body.translation = to_local(body.translation) # body.translation = to_local(body.global_transform.origin)
		#yield(get_tree(), "idle_frame")
		add_child(body)
		
		body.rotation -= rotation
		body.wait_a_fcking_moment = false


sync func remove_passatger(body):
	if body.get_parent() == self: # així també se soluciona el bug 14578 pq si bé surten de la nau comq encara tenen de node pare el /Troops, no s'executa
		print("surt de " + name + " " + body.name)
		body.global_transform.origin = to_global(body.global_transform.origin)
		remove_child(body)
		if body.is_in_group("AI"):
			get_node("/root/Main/Troops").add_child(body)
		elif body.is_in_group("Ships"):
			get_node("/root/Main/Vehicles").add_child(body)
			# treure'n també el fill si no es fa sol
			body.rotation += rotation
		elif body.is_in_group("Players"):
			get_node("/root/Main").add_child(body)
		else:
			return
		return


