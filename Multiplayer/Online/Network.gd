extends Node

# Aquestes constants defineixen la configuaració necesaria per a crear un client o un servidor
const DEFAULT_IP : String = '127.0.0.1' # Per defecte, está definit com a "localhost", es a dir conexió local
const DEFAULT_PORT : int = 31406 # Els jugador podrán canviar la ip i el port (aquest es degut a que així ordiandors amb la mateixa xarxa podrán jugar en servidors diferents)
const MAX_PLAYERS : int = 5 # El nombre màxim de peers al servidor

# La variable players conté tot el llistat de "self_datas" de tots els jugadors, també el propi
# Array de diccionaris
var players1 : Dictionary = { }
var players2 : Dictionary = { }

# Conté totes les variables de cada peer necesaries per inicialitzar al jugador
# Array de diccionaris
var self_data1 : Dictionary = { name = "", position = Vector3(0, 2, 0), rotation = 0.0, crounching = false,
		health = 0, is_alive = false, team = 0, is_in_a_vehicle = false } # Classe i is_alive = si té 0 vida
var self_data2 : Dictionary = self_data1.duplicate() 
var self_data3 : Dictionary = self_data1.duplicate()
var self_data4 : Dictionary = self_data1.duplicate()
# Crear una nova variable ja que self_data1 es només per a la inicialització i l'equip i classe es poden canviar durant la partida
# var self_conifg or player_config

# Conté totes les variables de cada peer necesaries per inicialitzar la partida
var match_data : Dictionary = { recived = false, vehicles_data = [], troops_data = [], capital_ships_data = [] }

signal player_disconnected
signal server_disconnected

func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
# warning-ignore:return_value_discarded
	get_tree().connect('network_peer_connected', self, '_on_player_connected')

func create_server(player_nickname):
	self_data1.name = player_nickname # El primer pas tant per a crear un servidor com un client es definir el mot que tindrà el jugador en la partida
	players1[1] = self_data1 # El "self_data1" local s'afegeix al llistat de "players" i ocupa la posició 1, ja que el servidor sempre té aquesta id
	if LocalMultiplayer.number_of_players == 2:
		self_data2.name = player_nickname
		players2[1] = self_data2
	var peer = NetworkedMultiplayerENet.new() # Es crea un peer
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS) # Es crea un servidor amb la configuració establerta
	get_tree().set_network_peer(peer) # S'inicialitza el peer juntament amb el servidor i la API

func connect_to_server(player_nickname, connect_ip):
	self_data1.name = player_nickname
# warning-ignore:return_value_discarded
	get_tree().connect('connected_to_server', self, '_connected_to_server') # Conectem les dos funcions i la senyal serà emessa tan aviat com el peer es connect-hi al servidor
	var peer = NetworkedMultiplayerENet.new() # Es crea un peer
	peer.create_client(connect_ip, DEFAULT_PORT) # Es crea un client amb la configuració establerta, en aquest cas es passa la ip (externa), en aquest cas la local, i el port
	get_tree().set_network_peer(peer) # S'inicialitza el peer juntament amb el servidor i la API

func _connected_to_server():
	# Si tot va bé, aquesta funció s'inicialitza desde la funció "connect_to_server"
	var local_player_id = get_tree().get_network_unique_id() # El primer que fem es fer servir la id única del jugador com a índex en el nostre array "players"
	# *Cada peer conectat té la seva propia id única, el servidor es sempre la id '1' (per aixó l'usem en la funció "create_server") i cada altre peer que s'uneixi a la xarxa rep una id que es major que '1'
	var i = LocalMultiplayer.number_of_players
	if i == 2:
		players2[local_player_id] = self_data2
	players1[local_player_id] = self_data1 # I establim la informació fent servir el "self_data1" local
	# Es crida a la funció amb els parametres de la id local i el "self_data1" local per a crear un jugador en el servidor
	# Aquesta crida només va dirigida al servidor i no als altres peers ja que encara no sap quins hi han
	while i > 0: # Multijugador local
		rpc("_send_player_info", local_player_id, get("self_data" + String(i)), i) # *remote procedure call: la funció serà executada en els peers que la tinguin
		i -= 1
	rpc_id(1, "_request_match_info", local_player_id)

# S'executa quan es desconnecta un jugador
func _on_player_disconnected(id):
	if players2.has(id):
		var player : Player = get_node("/root/Main/Splitscreen/Viewport2").get_node(str(id))
		if player.get_node("Interaction").is_in_a_vehicle:
			player.get_node("Interaction").current_vehicle.get_node("HealthSystem").take_damage(INF)
		
		player.set_process(false) # Es pot treure?
		player.get_node("/root/Main/Splitscreen/Viewport2").get_node(str(id)).queue_free()
		
		players2.erase(id)
	
	var player : Player = get_node("/root/Main/Splitscreen/Viewport1").get_node(str(id))
	if player.get_node("Interaction").is_in_a_vehicle:
		player.get_node("Interaction").current_vehicle.get_node("HealthSystem").take_damage(INF)
	
	player.set_process(false) # Es pot treure?
	player.queue_free()
	
	players1.erase(id)

# S'executa quan es connecta un nou jugador (poden ser els que ja hi son o els que s'uniran), la seva utilitat es sincronitzar els jugadors que es connectin o els ja connectats amb la partida de cadascun (a excepció del servidor)
func _on_player_connected(connected_player_id):
	var local_player_id = get_tree().get_network_unique_id()
	if not get_tree().is_network_server():
		# Si no es el servidor, el crida per a demanar-li la informació del nou jugador
		# El servidor no ho fa ja que ja té tots els clients sincronitzats
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)

remote func _request_player_info(request_from_id, player_id):
	if get_tree().is_network_server():
		# Si es el servidor, li envia la informació del nou jugador a qui la demani
		# Comprova si hi han 2 jugadors
		if players2.has(player_id):
			rpc_id(request_from_id, '_send_player_info', player_id, players2[player_id], 2)
		rpc_id(request_from_id, '_send_player_info', player_id, players1[player_id], 1)

# A function to be used if needed. The purpose is to request all players in the current session.
remote func _request_players(request_from_id):
	if get_tree().is_network_server():
		for peer_id in players1:
			if peer_id != request_from_id:
				rpc_id(request_from_id, "_send_player_info", peer_id, players1[peer_id], 1)
		
		for peer_id in players2:
			if peer_id != request_from_id:
				rpc_id(request_from_id, "_send_player_info", peer_id, players2[peer_id], 2)

"""
La paraula clau "remote" fa referència a que la funció s'executarà en tots el peers menys en el que l'execut-hi;
d'altra banda, la paraula clau "sync" fa referència a que s'executarà en tots els peers 
En aquest cas es fa servir la paraula clau "remote" ja que al iniciar la partida ja s'instancia el jugador local però al servidor no, es a dir que si fos sync el jugador local estaria duplicat
"""
remote func _send_player_info(id, info, number_of_player):
	# S'afegeix la informació en l'array "players"
	if number_of_player == 1:
		players1[id] = info
	elif number_of_player == 2:
		players2[id] = info
	else:
		breakpoint
	
	var new_player = load("res://Troops/Player/Player.tscn").instance() # S'instancia un nou jugador
	new_player.name = str(id) # Se li canvia el nom al de la seva id única
	new_player.set_network_master(id) # S'estableix com a "network master", així que el sistema local serà el "master" d'aquest node
	# Si és un player2 es diferent, aixó quan poguem treure els players dels viewports no serà necesari
	# I permetrà que hi hagi camara d'espectador
	if number_of_player == 1:
		$'/root/Main/Splitscreen/Viewport1'.add_child(new_player) # S'afegeix al joc
	elif number_of_player == 2:
		if not $'/root/Main/Splitscreen/Viewport2':
			var node = Node.new()
			node.name = "Viewport2"
			$'/root/Main/Splitscreen'.add_child(node)
		$'/root/Main/Splitscreen/Viewport2'.add_child(new_player)
	new_player.init(info.name, info.position, info.crounching, info.health, info.is_alive, info.is_in_a_vehicle) # S'inicalitza el jugador

remote func _request_match_info(request_from_id) -> void:
	var current_vehicles_data := []
	for vehicle in get_node("/root/Main/Vehicles").get_children():
		current_vehicles_data.resize(current_vehicles_data.size() + 1)
		current_vehicles_data[current_vehicles_data.size() - 1] = vehicle.get_node("VehicleNetwork").vehicle_data
	
	var current_troops_data := []
	for troop in get_node("/root/Main/Troops").get_children():
		current_troops_data.resize(current_troops_data.size() + 1)
		current_troops_data[current_troops_data.size() - 1] = troop.get_node("TroopNetwork").troop_data
	
	var current_capital_ships_data := []
	for ship in get_node("/root/Main/CapitalShips").get_children():
		current_capital_ships_data.resize(current_capital_ships_data.size() + 1)
		var ship_data = { name = ship.name, health = ship.get_node("HealthSystem").health }
		current_capital_ships_data[current_capital_ships_data.size() - 1] = ship_data
	
	if get_tree().is_network_server():
		# Si es el servidor, li envia la informació de la partida a qui la demani
		rpc_id(request_from_id, '_send_match_info', current_vehicles_data, current_troops_data, current_capital_ships_data)

remote func _send_match_info(vehicles_data : Array, troops_data : Array, capital_ships_data : Array):
	match_data.vehicles_data = vehicles_data
	match_data.troops_data = troops_data
	match_data.capital_ships_data = capital_ships_data
	match_data.recived = true

remote func _send_player_config(id, team, number_of_player):
	if number_of_player == 1:
		players1[id].team = team
	elif number_of_player == 2:
		players2[id].team = team
	else:
		breakpoint

func update_info(id : int, position : Vector3, rotation : float, crounching : bool, health : int, is_alive : bool, is_in_a_vehicle : bool, number_of_player : int) -> void:
	# Canviar?
	if number_of_player == 1:
		players1[id].position = position
		players1[id].rotation = rotation
		players1[id].crounching = crounching
		players1[id].health = health
		players1[id].is_alive = is_alive
		players1[id].is_in_a_vehicle = is_in_a_vehicle
	elif number_of_player == 2:
		players2[id].position = position
		players2[id].rotation = rotation
		players2[id].crounching = crounching
		players2[id].health = health
		players2[id].is_alive = is_alive
		players2[id].is_in_a_vehicle = is_in_a_vehicle
	
	# Error ja que no passa ni l'equip ni el nom
	# players1[id] = [position, rotation, health, is_alive, is_in_a_vehicle]
