extends Node

onready var physics : ShipPhysics = get_node("../../Physics") # ¿?
onready var ship : Ship = get_node("../../") # ¿?

var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var strafe := 0.0
var throttle := 0.0
export(float, -1, 1) var min_throttle := 0.3

# How quickly reacts to input
# Move Towards 0.5
const THROTTLE_SPEED := 2.5
const ROLL_SPEED := 2.5

var mouse_input := Vector2()
var input_device : int

var move_right_action := "move_right"
var move_left_action := "move_left"
var move_forward_action := "move_forward"
var move_backward_action := "move_backward"

var camera_down_action := "camera_down"
var camera_up_action := "camera_up"
var camera_left_action := "camera_left"
var camera_right_action := "camera_right"

var target: Vector3 = Vector3(100, 2000, 100)

var boost_multi: = 1.0

var distancia_per_comencar_a_frenat := 500.0
var a_partir_daqui_min := 200.0

var min_raycast_longitude := 0.7

var going_to_cs = false

var raycast_multiplier = 1

func _ready() -> void:
	pass


func _physics_process(delta):
	if not going_to_cs:
		if Input.is_action_just_pressed("CANVI_TAR"):
			var davant = get_node("/root/Main/CapitalShips/EntradaDavant").translation
			var darrere = get_node("/root/Main/CapitalShips/EntradaDarrere").translation
			var dsit_davant = owner.global_transform.origin.distance_to(davant)
			var dist_darrere = owner.global_transform.origin.distance_to(darrere)
			
			if dsit_davant < dist_darrere:
				target = davant
			else:
				target = darrere
			
			distancia_per_comencar_a_frenat = 700
			a_partir_daqui_min = 200
			min_raycast_longitude = 0.2
			going_to_cs = true
	else:
		if owner.global_transform.origin.distance_to(target) < 30: #abs(owner.global_transform.origin.y - target.y) < 5:
			distancia_per_comencar_a_frenat = 1500
			a_partir_daqui_min = 500
			raycast_multiplier = 0.3
			target = get_node("/root/Main/CapitalShips/CentreHangar").translation
	
	# roll = clamp(lerp(roll, (Input.get_action_strength(move_right_action) - Input.get_action_strength(move_left_action)), delta * ROLL_SPEED), -1, 1)
	
	update_yaw_and_ptich(delta)
	#update_throttle(move_forward_action, move_backward_action, delta)
	var dist = owner.global_transform.origin.distance_to(target)
	# si està en mode IA que no pugui ser menor que 0
	update_throttle(clamp(dist - a_partir_daqui_min/distancia_per_comencar_a_frenat - a_partir_daqui_min, 0.3, 1), delta)


func update_yaw_and_ptich(delta) -> void:
	var desired_oirent : Transform = owner.global_transform.looking_at(target, Vector3.UP)
	desired_oirent = desired_oirent.basis.rotated(desired_oirent.basis.y, deg2rad(180))
	
	owner.get_node("MeshInstance").global_transform.basis = desired_oirent.basis # No facis slerp a això pq si no fa ziga-zagues 
	owner.get_node("MeshInstance").global_transform.basis = owner.get_node("MeshInstance").global_transform.basis.slerp(desired_oirent.basis, 0.7 * delta) # No facis slerp a això pq si no fa ziga-zagues 
	
	var def_rot = owner.get_node("MeshInstance").rotation
	def_rot = def_rot.normalized()
	#def_rot.z = 0
	#owner.get_node("MeshInstance").rotation.z = 0
	
	# Per ser totalemnt correctes ->  x i y haurien de ser un Vector 2 normalitzat pq no puga girar més fort que el player i que sempre giri el màxim
	#pitch = def_rot.x
	#yaw = def_rot.y
	#roll = def_rot.z
	
	DebugDraw.draw_line_3d(owner.global_transform.origin, target, Color(1, 1, 0))
	
	# COM AL JOC ANTERIOR
	# AQUEST PRINT POT SER LA SOLUCIÓ A TOTS ELS MEUS PROBLEMES!!!
	owner.get_node("MeshInstance").global_transform.basis = owner.global_transform.basis.slerp(desired_oirent.basis, 0.7 * delta)
	#print(owner.get_node("MeshInstance").rotation)
	var uwu = owner.get_node("MeshInstance").rotation * 80 # no normalitzis la rotació del fill pq imagina't que li queda molt poc en tots els axis, faràs que es mogui molt i, vagi ebri
	#print(uwu)
	# es multiplica per un nombre gran pq l'slerp és molt petit
	# com més alt el nombre pel qual es multiplica millor, més precís (em penso) (potser fins i tot se centra de pressa a l'eix Y), però
	# no ha de ser massa alt, pq pot tornar a ser ebri (sobretot si l'Slerp és massa petit)
	if uwu.length() > 1: # ens assegurem q no sigui molt petit
		uwu = uwu.normalized()
	
	# no cal lerp? i pq al throttle sí?
	roll = uwu.z
	
	pitch = uwu.x
	yaw = uwu.y
	
	var fotut = false
	
	boost_multi = 1
	
	var up = false
	var down = false
	var right = false
	var left = false
	
	owner.get_node("ColDetectForward").cast_to = Vector3(0, 0, 150 * raycast_multiplier)
	owner.get_node("ColDetectDown").cast_to = Vector3(0, -75 * raycast_multiplier, 150 * raycast_multiplier)
	owner.get_node("ColDetectUp").cast_to = Vector3(0, 75 * raycast_multiplier, 150 * raycast_multiplier)
	owner.get_node("ColDetectRight").cast_to = Vector3(-75 * raycast_multiplier, 0, 150 * raycast_multiplier)
	owner.get_node("ColDetectLeft").cast_to = Vector3(75 * raycast_multiplier, 0, 150 * raycast_multiplier)
	
	
	"""
	# fer-ho amb la velocitat?
	var dist = owner.global_transform.origin.distance_to(target)
	var multi = clamp(((dist - a_partir_daqui_min)/(distancia_per_comencar_a_frenat - a_partir_daqui_min)), min_raycast_longitude, 1)
	#print(multi)
	owner.get_node("ColDetectForward").cast_to = Vector3(0, 0, 300 * multi)
	owner.get_node("ColDetectDown").cast_to = Vector3(0, -150 * multi, 300 * multi)
	owner.get_node("ColDetectUp").cast_to = Vector3(0, 150 * multi, 300 * multi)
	owner.get_node("ColDetectRight").cast_to = Vector3(-150 * multi, 0, 300 * multi)
	owner.get_node("ColDetectLeft").cast_to = Vector3(150 * multi, 0, 300 * multi)
	
	#owner.get_node("ColDetectForward").force_raycast_update()
	"""
	
	if (owner.get_node("ColDetectUp") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectUp").cast_to)), Color.blue)
		pitch = 1 # ves avall
		up = true
	if (owner.get_node("ColDetectDown") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectDown").cast_to)), Color.blue)
		pitch = -1 # vés amunt
		down = true
	# No elif pq si no, no es pot posar a true up i down
	
	# No toca ni a dalt ni a baix però si endavant
	if not down and not up and (owner.get_node("ColDetectForward") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectForward").cast_to)), Color.brown)
		pitch = -1 # Tant se val si -1 o 1, pq no toca enlloc
	elif down and up: # Toca a dalt i a baix
		if not (owner.get_node("ColDetectForward") as RayCast).is_colliding(): # No toca endavant
			pitch = 0
			# vés endavant
		else: # Toca per tot l'eix vertical
			if (owner.get_node("ColDetectUp") as RayCast).get_collision_point().distance_to(owner.global_transform.origin) - (owner.get_node("ColDetectDown") as RayCast).get_collision_point().distance_to(owner.global_transform.origin) > 20:
				if (owner.get_node("ColDetectUp") as RayCast).get_collision_point().distance_to(owner.global_transform.origin) > (owner.get_node("ColDetectDown") as RayCast).get_collision_point().distance_to(owner.global_transform.origin):
					pitch = -1
				else:
					pitch = 1
			else: # Si són a la mateixa distància, és a dir, una paret plana per exemple
				pitch = uwu.x
				
			#pitch = uwu.x # Això o el punt que quedi més lluny (amunt o avall)
			fotut = true
			# Toca amunt avall i davant
	
	
	# En un món ideal, la llargada dels RayCast dependria de la velocitat de la nau
	# dreta esquerra
	if (owner.get_node("ColDetectRight") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectRight").cast_to)), Color.blue)
		yaw = 1 # veé esquerra
		right = true
	# No elif pq si no, no es pot posar a true right i left
	if (owner.get_node("ColDetectLeft") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectLeft").cast_to)), Color.blue)
		yaw = -1 # vés dreta
		left = true
	
	# No toca ni a dreta ni a esq però si endavant
	if not left and not right and (owner.get_node("ColDetectForward") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectForward").cast_to)), Color.brown)
		yaw = 1 # Tant se val si -1 o 1, pq no toca enlloc
	elif right and left: # Toca dreta i esquerra
		if not (owner.get_node("ColDetectForward") as RayCast).is_colliding(): # No toca endavant
			yaw = 0
			# vés endavant
		else: # toca per tot arreu
			# Com més baix el número amb què es compara millor anirà a dintre de la CS (menys xocarà), però, segurament, li costi més d'entar
			if (owner.get_node("ColDetectRight") as RayCast).get_collision_point().distance_to(owner.global_transform.origin) - (owner.get_node("ColDetectLeft") as RayCast).get_collision_point().distance_to(owner.global_transform.origin) > 20:
				if (owner.get_node("ColDetectRight") as RayCast).get_collision_point().distance_to(owner.global_transform.origin) > (owner.get_node("ColDetectLeft") as RayCast).get_collision_point().distance_to(owner.global_transform.origin):
					yaw = -1
				else:
					yaw = 1
			else: # Si són a la mateixa distància, és a dir, una paret plana per exemple
				yaw = uwu.y
			if fotut: # Toca amunt dreta, esquerra i, a més, amunt, avall i endevant
				boost_multi = 0.25
	
	owner.get_node("MeshInstance").rotation = Vector3.ZERO
	
	# COM AL JOC ANTERIOR
	#owner.global_transform.basis = owner.global_transform.basis.slerp(desired_oirent.basis, 0.7 * delta)
	#owner.translation += owner.global_transform.basis.z * 100 * delta

	
	"""
	mouse_input.x = get_node("../../PlayerHUD").cursor_input.x
	mouse_input.y = -get_node("../../PlayerHUD").cursor_input.y
	
	# no cal lerp? i pq al throttle sí?
	pitch = mouse_input.y if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or input_device == -1 else Input.get_action_strength(camera_down_action) - Input.get_action_strength(camera_up_action)
	yaw = -mouse_input.x if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or input_device == -1 else Input.get_action_strength(camera_left_action) - Input.get_action_strength(camera_right_action)
	"""


func update_throttle(value : float, delta : float) -> void:
	var targett := throttle
	targett = clamp(value * boost_multi, min_throttle, 1)
	# Change to move_towards
	throttle = clamp(lerp(throttle, targett, delta * THROTTLE_SPEED), -1, 1)


"""
func update_throttle(increase_action : String, decrease_action : String, delta : float) -> void:
	var target := throttle
	target = clamp(Input.get_action_strength(increase_action) - Input.get_action_strength(decrease_action), min_throttle, 1)
	# Change to move_towards
	throttle = clamp(lerp(throttle, target, delta * THROTTLE_SPEED), -1, 1)
"""
