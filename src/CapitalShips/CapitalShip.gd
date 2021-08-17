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
	print("BODY_ENTERED: " + body.name)
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("add_passatger", body.get_path())
	else:
		add_passatger(body.get_path())


func _on_Area_body_exited(body):
	print("BODY_EXITED: " + body.name)
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("remove_passatger", body.get_path())
	else:
		remove_passatger(body.get_path())


sync func add_passatger(path):
	var body = get_node(path)
	if not body:
		return
	if body.get_parent() == self: # per a les naus que hi són des del principi
		return
	if body.is_in_group("Ships") or body.is_in_group("Troops"):
		
		if body.wait_a_fcking_moment:
			return
		
		"""
		if body.is_in_group("AI"):
			Network.troops_can_move = true
		"""
		
		print("entra a " + name + " " + body.name)
		
		# issuea 14578
		body.wait_a_fcking_moment = true
		body.get_parent().remove_child(body)
		body.translation = to_local(body.translation) # body.translation = to_local(body.global_transform.origin)
		#yield(get_tree(), "idle_frame")
		add_child(body)
		
		body.rotation -= rotation
		body.wait_a_fcking_moment = false


sync func remove_passatger(path):
	var body = get_node(path)
	if not body:
		return
	"""
	comprovant si el pare és la nau també se soluciona el bug 14578, car si bé 
	surten de la nau, puix encara tenen de node pare el /Troops, no s'executa,
	ÉS A DIR, no cal comprovar si wait_a_fcking_moment
	"""
	if body.get_parent() == self:
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


# que amb add-pasatger() ja es pugui fer això
sync func add_fill(path):
	print("s'intenta afegir " + path + " a " + name)
	var body = get_node(path)
	if not body:
		return
	
	print("entra a " + name + " " + body.name + " mitjançant add_fill")
	
	body.get_parent().remove_child(body)
	add_child(body)
	body.translation = to_local(body.translation)
