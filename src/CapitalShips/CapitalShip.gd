extends Spatial
class_name CapitalShip

export var team : int = 0

export var cap_ship_id : int = 0


func _ready():
	$Hangar/Area.connect("body_entered", self, "_on_Area_body_entered", [])
	$Hangar/Area.connect("body_exited", self, "_on_Area_body_exited", [])
	
	if name == "CapitalShip2":
		$Label.rect_position.y -= 50


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
			# if child has_methoud("take_damage")
			if child.is_in_group("Ships") or child.is_in_group("Troops"): # o vehicle
				child.get_node("HealthSystem").take_damage(INF, true) # gradual
		_explode()


sync func _explode() -> void:
	# Anim 
	queue_free()


func _on_Area_body_entered(body):
	print("BODY_ENTERED: " + body.name)
	
	if not body.is_in_group("Ships") and not body.is_in_group("Troops"):
		return
	if body.wait_a_fcking_moment:
		return
	if body.get_parent() == self: # per a les naus que hi són des del principi
		return
	
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("add_passatger", body.get_path())
	else:
		add_passatger(body.get_path())


func _on_Area_body_exited(body):
	"""
	Cal comprovar si body.wait_a_fcking_moment, perquè això ho resolíem
	comprovant si el pare és la nua capital -ergo, ja ha passat per _on_Area_body_entered 
	i add_passatger() una vegada-, però amb les naus que ja són dins de la nau capital
	això no funciona
	"""
	# Si abans de fer cap rpc, comprov si body.wait_a_fcking_moment, potser
	# ens estalviaríem uns quants errors, nogensmenys, s'hauria de repetir una mica de codi
	# del remove_passatger
	print("BODY_EXITED: " + body.name)
	
	if not body.is_in_group("Ships") and not body.is_in_group("Troops"):
		return
	if body.wait_a_fcking_moment:
		return
	if body.get_parent() != self:
		return
	
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("remove_passatger", body.get_path())
	else:
		remove_passatger(body.get_path())


sync func add_passatger(path):
	print(path)
	var body = get_node(path)
	if not body:
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


sync func remove_passatger(path):
	var body = get_node(path)
	if not body:
		return
	
	print("surt de " + name + " " + body.name)
	
	body.wait_a_fcking_moment = true # per a quan un client tanca el joc
	body.global_transform.origin = to_global(body.global_transform.origin)
	remove_child(body)
	
	if body.is_in_group("AI"):
		get_node("/root/Main/Troops").add_child(body)
	elif body.is_in_group("Ships"):
		get_node("/root/Main/Vehicles").add_child(body)
		# la tropa i el jugador surten sols
		body.rotation += rotation
	elif body.is_in_group("Players"):
		get_node("/root/Main").add_child(body)
	
	body.wait_a_fcking_moment = false


# que amb l'add-pasatger() ja es pugui fer això
sync func add_fill(path):
	print("s'intenta afegir " + path + " a " + name)
	var body = get_node(path)
	if not body:
		return
	
	print("entra a " + name + " " + body.name + " mitjançant add_fill")
	
	body.get_parent().remove_child(body)
	add_child(body)
	body.translation = to_local(body.translation)
