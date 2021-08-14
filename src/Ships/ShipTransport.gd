extends Node

export var m_team := 0
export var mesh : NodePath

var current_cp := ""


func _ready() -> void:
	pass


func _process(delta : float) -> void:
	# Cambiar quan les naus tinguin models propis
	set_material()
	
	if get_parent().state == get_parent().State.LANDED and not current_cp:
		instance_cp()
	elif get_parent().state != get_parent().State.LANDED and current_cp:
		delete_cp()
	
	"""
	Em pens q açò ja no cal
	if get_parent().state == get_parent().State.LANDED and current_cp:
		if get_node(current_cp).global_transform.origin != get_parent().translation:
			get_node(current_cp).translation = get_parent().translation
	"""


func instance_cp() -> void:
	var main : Main = get_node("/root/Main/") # hi ha cap manera millor?
	var cp = main.instance_cp(Vector3.ZERO, false, m_team) # Pos. = 0 perquè ara serà fill nostre
	
	cp.get_parent().remove_child(cp)
	get_parent().add_child(cp)
	
	cp.get_node("MeshInstance").hide()
	connect("tree_exited", cp, "queue_free")
	current_cp = cp.get_path()


func delete_cp() -> void:
	if not current_cp: #== "":
		return
	get_node(current_cp).queue_free()
	current_cp = ""


func set_material() -> void:
	return
	
	if m_team == 0:
		pass
	elif m_team == get_node("/root/Main").local_players[0].get_node("TroopManager").m_team:
		get_node(mesh).set_material_override(load("res://assets/materials/command_post/blue.tres"))
	else:
		get_node(mesh).set_material_override(load("res://assets/materials/command_post/red.tres"))
	
