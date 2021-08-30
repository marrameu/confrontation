extends Node

onready var physics : ShipPhysics = get_node("../../Physics") # ¿?
onready var ship : Ship = get_node("../../") # ¿?

const THROTTLE_SPEED := 2.5

# Valors entre -1 i 1
var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var strafe := 0.0
var throttle := 0.0
export(float, -1, 1) var min_throttle := 0.3

var target: Vector3 = Vector3(100, 2000, 100)

var raycast_offset = 6
var detection_dist = 50

var entered = false

var boost_multi: = 1.0

func enter():
	owner.leave()
	owner.is_ai = true


func _physics_process(delta):
	if Input.is_action_just_pressed("MODE_DeU"):
		if randi() % 2 and not entered and not owner.is_player:
			entered = true
			enter()
		else:
			entered = true
	
	if owner.is_ai:
		move_forward(delta)
		if target:
			turn(delta)
	
	# roll = clamp(lerp(roll, 0, delta * ROLL_SPEED), -1, 1)


func move_forward(delta):
	update_throttle(1, delta)


# Va una mica ebri!, però fa el fet. S'hauria de fer amb matemàtiques, passant la desired_oirent a local, com ho feia al del 2017 (amb l'Slerp però amb pitch, yaw i roll)
# Ja no va ebri!, però li costa de centrar-se del tot al voltant de l'eix Y, segurament és deu a fer-ho d'aquesta manera, amb físiques i amb un Slerp aproxiament
# no obstant això, aquest és el millor mètode que he trobat i val a dir que n'estic prou orgullós
func turn(delta):
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
	
	if (owner.get_node("ColDetectDown") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectDown").cast_to)), Color.blue)
		pitch = -1 # vés amunt
		down = true
	# No elif pq si no, no es pot posar a true up i down
	if (owner.get_node("ColDetectUp") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectUp").cast_to)), Color.blue)
		pitch = 1 # ves avall
		up = true
	
	# No toca ni a dalt ni a baix però si endavant
	if not down and not up and (owner.get_node("ColDetectForward") as RayCast).is_colliding():
		DebugDraw.draw_line_3d(owner.global_transform.origin, owner.global_transform.origin+(owner.global_transform.basis.xform(owner.get_node("ColDetectForward").cast_to)), Color.brown)
		pitch = -1 # Tant se val si -1 o 1, pq no toca enlloc
	elif down and up: # Toca a dalt i a baix
		if not (owner.get_node("ColDetectForward") as RayCast).is_colliding(): # No toca endavant
			pitch = 0
			# vés endavant
		else: # Toca per tot l'eix vertical
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
		elif fotut: # toca per tot arreu
			boost_multi = 0.25
			print(yaw, pitch)
			
			pass # U turn
			# Toca amunt dreta, esquerra i, a més, amunt, avall i endevant
	
	owner.get_node("MeshInstance").rotation = Vector3.ZERO
	
	# COM AL JOC ANTERIOR
	#owner.global_transform.basis = owner.global_transform.basis.slerp(desired_oirent.basis, 0.7 * delta)
	#owner.translation += owner.global_transform.basis.z * 100 * delta


func update_throttle(value : float, delta : float) -> void:
	var target := throttle
	target = clamp(value * boost_multi, min_throttle, 1)
	# Change to move_towards
	throttle = clamp(lerp(throttle, target, delta * THROTTLE_SPEED), -1, 1)
