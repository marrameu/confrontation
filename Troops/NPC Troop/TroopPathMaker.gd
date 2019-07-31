extends Node

# Movement
const SPEED := 4

var begin := Vector3()
var end := Vector3()

var path := []

func _ready() -> void:
	pass

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	# Walk
	if path.size() > 1:
		# Distance to stop
		if get_parent().global_transform.origin.distance_to(end) < 4:
			path = []
			return
		
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
			get_parent().translation = atpos + Vector3(0, 1.15, 0)
		
		if path.size() < 2:
			path = []

func _update_path() -> void:
	var p = get_node("/root/Main/Map/Navigation").get_simple_path(begin, end, true)
	path = Array(p) # Vector3 array too complex to use, convert to regular array
	path.invert()
