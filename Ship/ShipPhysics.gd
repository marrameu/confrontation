extends Node

class_name ShipPhysics

onready var ship = get_parent()

var force_multiplier := 1.0

var linear_force := Vector3(0, 0, 200)
var angular_force := Vector3(90, 90, 175) / 100.0

var applied_linear_force := Vector3()
var applied_angular_force := Vector3()

var desired_linear_force := Vector3()
var desired_angular_force := Vector3()

var angular_drag := 3.5 # ¿?
var linear_drag := 2.0 # ¿?

func _ready():
	pass

func _process(delta : float) -> void:
	if get_parent().state == 1:
		add_force(applied_linear_force * force_multiplier, delta)
		add_torque(applied_angular_force * force_multiplier, delta)
	elif get_parent().state == 2:
		get_parent().set_linear_velocity(Vector3(0, 2.5, 0)) 
	elif get_parent().state == 3:
		get_parent().set_mode(RigidBody.MODE_KINEMATIC)
		if not (get_node("../Tail") as RayCast).is_colliding():
			get_parent().translation += Vector3(0, -5.0 * delta, 0)
			stabilize_rotation(delta)
		else:
			get_parent().state = 0
	elif get_parent().state == 0:
		get_parent().set_mode(RigidBody.MODE_KINEMATIC)
		# Quitarlo proximamente, hacer que dependiendo de que tan cerca estes de el suelo te muevas más rapido o hacer que tail
		# apunte hacia abajo en world cordinates, pero para salir un raycast como tail pero en local cordinates tiene
		# que estar tocando el suelo
		stabilize_rotation(delta)

func set_physics_input(linear_input : Vector3, angular_input : Vector3):
	applied_angular_force = angular_input * angular_force
	applied_linear_force = linear_input * linear_force

func add_force(force : Vector3, delta : float):
	desired_linear_force = desired_linear_force.linear_interpolate(force, delta / linear_drag * 10)
	ship.linear_velocity = ship.global_transform.basis.xform(desired_linear_force)

func add_torque(torque : Vector3, delta : float):
	desired_angular_force = desired_angular_force.linear_interpolate(torque, delta / angular_drag * 10)
	ship.angular_velocity = ship.global_transform.basis.xform(desired_angular_force)

func stabilize_rotation(delta : float) -> void:
	var des_rot = get_parent().rotation.linear_interpolate(Vector3(), 1.2 * delta)
	get_parent().rotation = Vector3(des_rot.x, get_parent().rotation.y, des_rot.z)