tool
extends Gun

export var cam : NodePath

var action := ""

const hitmarkers := {
	0: preload("res://assets/interface/hitmarkers/hitmarker.png"),
	1: preload("res://assets/interface/hitmarkers/hitmarker_yellow.png"),
	2: preload("res://assets/interface/hitmarkers/hitmarker_red.png"),
}

func _get_configuration_warning() -> String:
	var warning := ""
	if not cam:
		warning = "No hi ha cap càmara asignada"
	return warning


func _ready() -> void:
	if get_tree().has_network_peer():
		if not is_network_master():
			$HUD/Crosshair.queue_free()


func _process(delta : float) -> void:
	if Engine.editor_hint:
		return
	
	if get_tree().has_network_peer():
		if not is_network_master():
			return
	
	var cam_basis : Basis = get_node(cam).global_transform.basis
	$RayCast.global_transform.origin = get_node(cam).global_transform.origin
	global_transform.basis = cam_basis.get_euler() + Vector3(deg2rad(180), 0, 0)
	
	if m_team != get_node("../../TroopManager").m_team: # On value changed
		m_team = get_node("../../TroopManager").m_team
	
	if action == "":
		action = get_parent().shoot_action
		return
	
	if Input.is_action_just_pressed(action):
		get_parent().attacking = true
		shooting = true
	elif not Input.is_action_pressed(action):
		get_parent().attacking = false
		shooting = false
	
	if not shooting:
		get_node(cam).get_parent().stop_shake_camera()


func _shake_camera():
	get_node(cam).get_parent().shake_camera()


func _on_shot(collider_path : NodePath):
	$HUD/Hitmarker.texture = hitmarkers[0]
	$HUD/Hitmarker/Timer.start()
	
	_on_kill(collider_path)


func _on_headshot(collider_path : NodePath):
	$HUD/Hitmarker.texture = hitmarkers[1]
	$HUD/Hitmarker/Timer.start()
	
	_on_kill(collider_path)


func _on_kill(collider_path : NodePath) -> void:
	var collider = get_node(collider_path)
	if collider.is_in_group("Troops") or collider.is_in_group("Ships"):
		if collider.get_node("HealthSystem").health - shot_damage <= 0:
			$HUD/Hitmarker.texture = hitmarkers[2]
			$HUD/Hitmarker/Audio.play()


func _on_Hitmarker_timeout():
	$HUD/Hitmarker.texture = null
