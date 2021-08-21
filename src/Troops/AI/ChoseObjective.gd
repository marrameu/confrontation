"""
Si no aprofito gaire aquest estat, moure-ho tot a la ToopStateMachine
"""
extends "TroopState.gd"

# per al client, tanmateix potser 1s no és prou (provar Hug) i potser s'hauria d'investigar l'arrel d'aquest problema
# o bé mirar si en lloc d'esperar x segons, puc fer canviar una variable des del servidor i quan canvia
# al client vol dir que ja està...
var wait_to_init := true


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func enter():
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return # emit_signal("finished", "client")?
	
	if wait_to_init:
		return
	
	update_nav_node()
	
	# Per a poder fer això, cal que l'space ja estigui esablert, això es fa, a l'inici de la partida,
	# establint-li la propietat abans (al mateix moment) d'instanciar-lo
	if owner.space:
		emit_signal("finished", "search_ship")
	else:
		emit_signal("finished", "go_to_cp") # des de ground idle decideix si ha de passar a GoToCP
		# o bé fer-ho des d'aquí:
		# if CPS:
			# emit_signal("finished", "go_to_cp")


func _on_InitTimer_timeout():
	wait_to_init = false
	enter()


func update_nav_node():
	if not owner.space:
		owner.get_node("PathMaker").navigation_node = get_node("/root/Main/Map/Navigation") # es pot fer millor
	else:
		update_cap_ship() # també es podria fer que la funció "update_cap_ship"
		# sols canviés l'"owner.my_cap_ship" i des d'aquí ja es canvia 
		# l'"owner.get_node("PathMaker").navigation_node", però tant és.
		# owner.get_node("PathMaker").navigation_node = owner.my_cap_ship.get_node("Navigation")


func update_cap_ship(): #bé, nse si seria millor update_navigation_node (for nav_node in get_all_nodes(Navigation)), o si aquesta funció hauria d'anar a SearchSHip
	owner.my_cap_ship = null # per si un cas, dubt que calgui
	
	var cap_ships = get_tree().get_nodes_in_group("CapitalShips")  # Com indic que ha de ser un Spatial? O un array de Spatials
	var closest_cap_ship_origin : Vector3 = Vector3.INF
	
	var my_origin : Vector3 = owner.global_transform.origin
	
	for cap_ship in cap_ships:
		var ship_origin : Vector3 = cap_ship.global_transform.origin
		if my_origin.distance_to(ship_origin) < my_origin.distance_to(closest_cap_ship_origin):
			closest_cap_ship_origin = ship_origin
			owner.my_cap_ship = cap_ship
			owner.get_node("PathMaker").navigation_node = cap_ship.get_node("Navigation")
	
	if not owner.my_cap_ship:
		print("ERROR: No Capital Ships")
	
	# ADD_PASSATGER DES D'AQUÍ?
