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

var stabilizing := false
var stabilized := false

var descense_vel := 0.0
var DESIRED_DESCENSE_VEL := 5.0


func _process(delta : float) -> void:
	if get_parent().state == get_parent().State.FLYING:
		add_force(applied_linear_force * force_multiplier, delta)
		add_torque(applied_angular_force * force_multiplier, delta)
		
	elif get_parent().state == get_parent().State.LEAVING:
		get_parent().set_linear_velocity(Vector3(0, 2.5, 0)) 
		
	elif get_parent().state == get_parent().State.LANDING:
		get_parent().set_mode(RigidBody.MODE_KINEMATIC)
		if not stabilized and not stabilizing:
			_stabilize_rotation()
			
		elif stabilized:
			descense_vel = lerp(descense_vel, DESIRED_DESCENSE_VEL, 0.1)
			get_parent().translation += Vector3(0, -descense_vel * delta, 0)
			
			if get_node("../Tail").is_colliding():
				get_parent().state = 0
				
				stabilizing = false
				stabilized = false
		
	elif get_parent().state == get_parent().State.LANDED:
		get_parent().set_mode(RigidBody.MODE_KINEMATIC)


func set_physics_input(linear_input : Vector3, angular_input : Vector3):
	applied_angular_force = angular_input * angular_force
	applied_linear_force = linear_input * linear_force


func add_force(force : Vector3, delta : float):
	desired_linear_force = desired_linear_force.linear_interpolate(force, delta / linear_drag * 10)
	ship.linear_velocity = ship.global_transform.basis.xform(desired_linear_force)


func add_torque(torque : Vector3, delta : float):
	desired_angular_force = desired_angular_force.linear_interpolate(torque, delta / angular_drag * 10)
	ship.angular_velocity = ship.global_transform.basis.xform(desired_angular_force)


func _stabilize_rotation(time : float = 2.0) -> void:
	# Calcular el temps
	time *= abs(get_parent().rotation.x) if abs(get_parent().rotation.x) > abs(get_parent().rotation.z) else abs(get_parent().rotation.z / 2)
	time += 0.25
	
	$Tween.interpolate_property(get_parent(), "rotation", get_parent().rotation, Vector3(0, get_parent().rotation.y, 0), time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	
	stabilizing = true

func _on_Tween_tween_all_completed():
	stabilized = true
