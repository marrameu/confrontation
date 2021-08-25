extends "OnFloor.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func enter():
	owner.get_node("PlayerMesh/rig/AnimationPlayer").play("Man_Run", -1, 0.7)
	
	"""
	L'inici és get_closest_point de la posició local de la tropa respete el node de navegació.
	Tant l'inici com el final han de ser coordenades locals respecte el node de navegació.
	"""
	var navigation_node = owner.get_node("PathMaker").navigation_node
	
	var wr = weakref(navigation_node) # Per si la nau ha petat? Caldir ara, amb l'State Machine?
	if !wr.get_ref():
		owner.die()
		return
	
	var begin : Vector3
	var end : Vector3
	
	var my_origin : Vector3 = owner.global_transform.origin
	
	# el begin s'ha de fer amb la pos. global de la tropa i després passar-la a local pq, si no, malament rai
	begin = navigation_node.to_local(my_origin)
	# get_closest_point perquè no es passi
	begin = navigation_node.get_closest_point(begin)
	
	var choosen_ship : Ship = null
	var ships = get_tree().get_nodes_in_group("Ships")
	var closest_ship_origin : Vector3 = Vector3.INF
	for ship in ships: # què fer si no hi ha ships?
		var ship_origin = ship.global_transform.origin
		if my_origin.distance_to(ship_origin) < my_origin.distance_to(closest_ship_origin):
			closest_ship_origin = ship_origin
	
	end = navigation_node.to_local(closest_ship_origin)
	end = navigation_node.get_closest_point(end)
	
	# No naus -> $PathMaker.navigation_node.get_closest_point(begin + Vector3(rand_range(-200, 200), 0, rand_range(-200, 200)))
	# CREAR UNA FUNCIO PER A ANAR A UN PUNT ALEATORI (EN UNA DISTÀNCIA ESPECÍFICA)
	
	owner.get_node("PathMaker").update_path(begin, end)


func _on_animation_finished(anim_name):
	if anim_name == "Man_Run":
		owner.get_node("PlayerMesh/rig/AnimationPlayer").play("Man_Run", -1, 0.7)
