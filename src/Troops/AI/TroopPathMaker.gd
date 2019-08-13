extends Node

# Movement
const SPEED := 5

var begin := Vector3()
var end := Vector3()

var min_distance := 5.0
var path := []

var finished := true


func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	# Walk
	if path.size() > 1:
		# Distance to stop
		if get_parent().global_transform.origin.distance_to(end) < min_distance:
			path = []
			finished = true
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
		
		if path.size() < 2:
			path = []

func update_path() -> void:
	var p = get_node("/root/Main/Map/Navigation").get_simple_path(begin, end, true)
	path = Array(p) # Vector3 array too complex to use, convert to regular array
	path.invert()

func clean_path() -> void:
	finished = true
	path = []
