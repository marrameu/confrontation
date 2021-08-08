extends Node

signal arrived

# Movement
const SPEED := 5

var begin := Vector3()
var end := Vector3()

var min_distance := 5.0
var path := []

var finished := true

var navigation_node : Navigation = null

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	# Walk
	if path.size() > 1:
		# Distance to stop
		if get_parent().global_transform.origin.distance_to(navigation_node.to_global(end)) < min_distance:
			path = []
			finished = true
			emit_signal("arrived")
			return
		
		finished = false
		var to_walk = delta * SPEED
		while to_walk > 0 and path.size() >= 2:
			var pfrom = path[path.size() - 1]
			var pto = path[path.size() - 2]
			var d = pfrom.distance_to(pto)
			if d <= to_walk:
				path.remove(path.size() - 1)
				to_walk -= d
			else:
				path[path.size() - 1] = pfrom.linear_interpolate(pto, to_walk/d)
				to_walk = 0
		
		if path.size() > 1:
			var atpos = path[path.size() - 1]
			get_parent().translation = atpos + Vector3(0, 1.4 + 0.015, 0) 
			"""
			No s'aplcia al transform global perque no hi hagin problemes amb
			les naus en moviment, nogensmenys, per poder fer-ho, cal que el 
			node de navegació tingui una translació local de 0,0,0 perquè, 
			altrament, la tropa hauria de ser filla del node de navegació.
			Això ha de ser així perquè el node de navegació dona la path
			respecte ell, una altra forma fóra -seria- en lloc de passar la
			path a global com havem fet fins ara, pasar-la a global i després
			a local respecte el node de la nau capital. 
			"""
		
		if path.size() < 2:
			path = []

func update_path(new_begin : Vector3, new_end : Vector3) -> void:
	begin = new_begin
	end = new_end
	
	var p = navigation_node.get_simple_path(begin, end, true)
	path = Array(p) # Vector3 array too complex to use, convert to regular array (nse q vol dir)
	path.invert()
	
	# Cal passar, ara, la path a coords. globals perquè aquestes s'apliquen directament a la posició de la tropa.
	# Quan les naus capitals es moguin, açò s'haurà de fer diferent, potser passant-les primer a global i després a local respecte el node base de la nau
	"""
	var i : int = 0
	for pos in path:
		path[i] =  navigation_node.to_global(pos)
		i += 1
	"""

func clean_path() -> void:
	finished = true
	path = []
