extends Node

# Aquestes constants defineixen la configuaració necesaria per a crear un client o un servidor
const DEFAULT_IP : String = "127.0.0.1" # Per defecte, está definit com a "localhost", es a dir conexió local
const DEFAULT_PORT : int = 31406
const MAX_PLAYERS : int = 5 

# La variable players conté tot el llistat de "self_datas" de tots els jugadors, també el propi
var players : Array = [ { }, { }, { }, { } ]

# Conté totes les variables de cada peer necesaries per inicialitzar al jugador
var self_datas : Array = [ { }, { }, { }, { } ]

# Crear una nova variable ja que self_data1 es només per a la inicialització i l'equip i classe es poden canviar durant la partida
# var self_conifg or player_config

# Conté totes les variables de necesaries per inicialitzar la partida
var match_data : Dictionary = { recived = false, vehicles_data = [], troops_data = [], capital_ships_data = [] }

signal player_disconnected
signal server_disconnected

func _ready():
	for i in range(0, self_datas.size()):
		self_datas[i] = { name = "Noname", position = Vector3(0, 2, 0), rotation = 0.0, crouching = false,
				health = 0, is_alive = false, team = 0, is_in_a_vehicle = false }
	
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')


func create_server(player_nickname):
	for i in range(0, LocalMultiplayer.number_of_players):
		self_datas[i].name = player_nickname
		players[i][1] = self_datas[i]
	
	var peer := NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)


func connect_to_server(player_nickname, connect_ip):
	for i in range(0, LocalMultiplayer.number_of_players):
		self_datas[i].name = player_nickname
	
	get_tree().connect('connected_to_server', self, '_connected_to_server') # Conectem les dos funcions i la senyal serà emessa tan aviat com el peer es connect-hi al servidor
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client(connect_ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)


# Si tot va bé, aquesta funció s'inicialitza des de la funció "connect_to_server"
func _connected_to_server():
	var id : int = get_tree().get_network_unique_id()
	var i = LocalMultiplayer.number_of_players
	
	while i > 0:
		players[i - 1][id] = self_datas[i - 1]
		# Aquesta crida només va dirigida al servidor i no als altres peers ja que encara no sap quins hi han
		rpc("_send_player_info", id, self_datas[i - 1], i)
		i -= 1
	
	rpc_id(1, "_request_match_info", id)


# S'executa quan es desconnecta un jugador
func _on_player_disconnected(id):
	# Es podria fer sense consultar quin local player és
	for i in range(0, players.size()):
		if players[i].has(id):
			var player # : Player 
			for node in get_tree().get_nodes_in_group("Players"):
				if node.online_id == id:
					player = node
			if player.get_node("Interaction").is_in_a_vehicle:
				player.get_node("Interaction").current_vehicle.get_node("HealthSystem").take_damage(INF)
			
			player.set_process(false) # Es pot treure?
			player.queue_free()
			
			players[i].erase(id)


# S'executa quan es connecta un nou jugador (poden ser els que ja hi son o els que s'uniran), la seva utilitat es sincronitzar els jugadors que es connectin o els ja connectats amb la partida de cadascun (a excepció del servidor)
func _on_player_connected(connected_player_id):
	var id = get_tree().get_network_unique_id()
	if not get_tree().is_network_server():
		# Si no es el servidor, el crida per a demanar-li la informació del nou jugador
		# El servidor no ho fa ja que ja té tots els clients sincronitzats
		rpc_id(1, '_request_player_info', id, connected_player_id)


remote func _request_player_info(request_from_id, player_id):
	if get_tree().is_network_server():
		# Si es el servidor, li envia la informació del nou jugador a qui la demani
		for i in range(0, players.size()):
			if players[i].has(player_id):
				rpc_id(request_from_id, '_send_player_info', player_id, players[i][player_id], i + 1)


# A function to be used if needed. The purpose is to request all players in the current session.
remote func _request_players(request_from_id):
	if get_tree().is_network_server():
		for i in range(0, players.size()):
			for peer_id in players[i]:
				if peer_id != request_from_id:
					rpc_id(request_from_id, "_send_player_info", peer_id, players[i][peer_id], i + 1)


remote func _send_player_info(id, info, number_of_player):
	# S'afegeix la informació en l'array "players"
	players[number_of_player - 1][id] = info
	
	var new_player = load("res://src/Troops/Player/Player.tscn").instance() # : Player 
	new_player.online_id = id
	new_player.name = String(id) + String(number_of_player)
	new_player.set_network_master(id) # S'estableix com a "network master", així que el sistema local serà el "master" d'aquest node
	new_player.number_of_player = number_of_player
	
	# potser això sobra ara 6/8/21
	var viewport : Viewport = get_node("/root/Main/Splitscreen/Viewport" + str(number_of_player))
	if not viewport:
		var node = Node.new()
		node.name = "Viewport" + str(number_of_player)
		$"/root/Main/Splitscreen".add_child(node)
		viewport = node
	#viewport.add_child(new_player)
	$"/root/Main".add_child(new_player)
	
	new_player.init(info.name, info.position, info.crouching, info.health, info.is_alive, info.is_in_a_vehicle) # S'inicalitza el jugador


remote func _request_match_info(request_from_id) -> void:
	var current_vehicles_data := []
	# Atenció!, això s'hauria de fer amb tags per les naus que es troben en les naus capitals
	# per tant, s'hauria de demanar la info. de les Naus capitals abans que la dels vehicles i demanar el parent
	
	var current_capital_ships_data := []
	for ship in get_node("/root/Main/CapitalShips").get_children():
		current_capital_ships_data.resize(current_capital_ships_data.size() + 1)
		var ship_data = { name = ship.name, health = ship.get_node("HealthSystem").health, id = ship.cap_ship_id } # el nom no caldria
		current_capital_ships_data[current_capital_ships_data.size() - 1] = ship_data
	
	for vehicle in get_node("/root/Main/Vehicles").get_children():
		current_vehicles_data.resize(current_vehicles_data.size() + 1)
		current_vehicles_data[current_vehicles_data.size() - 1] = vehicle.get_node("VehicleNetwork").vehicle_data
	
	var current_troops_data := []
	for troop in get_tree().get_nodes_in_group("AI"):
		current_troops_data.resize(current_troops_data.size() + 1)
		current_troops_data[current_troops_data.size() - 1] = troop.get_node("TroopNetwork").troop_data
	
	if get_tree().is_network_server():
		# Si es el servidor, li envia la informació de la partida a qui la demani
		rpc_id(request_from_id, '_send_match_info', current_vehicles_data, current_troops_data, current_capital_ships_data)


remote func _send_match_info(vehicles_data : Array, troops_data : Array, capital_ships_data : Array):
	match_data.vehicles_data = vehicles_data
	match_data.troops_data = troops_data
	match_data.capital_ships_data = capital_ships_data
	match_data.recived = true


remote func _send_player_config(id, team, number_of_player):
	players[number_of_player - 1][id].team = team


func update_info(id : int, position : Vector3, rotation : float, crouching : bool, health : int, is_alive : bool, is_in_a_vehicle : bool, number_of_player : int) -> void:
	players[number_of_player - 1][id].position = position
	players[number_of_player - 1][id].rotation = rotation
	players[number_of_player - 1][id].crouching = crouching
	players[number_of_player - 1][id].health = health
	players[number_of_player - 1][id].is_alive = is_alive
	players[number_of_player - 1][id].is_in_a_vehicle = is_in_a_vehicle
