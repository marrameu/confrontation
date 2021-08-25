extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# AÇÒ NO VA PQ AIXÒ S'EXECUTA DESPRÉS DEL READY DEL CP.GD
	for cp in get_children() :#as CP
		cp.start_team = get_parent().team
		cp.m_team = get_parent().team
		
		# cp.get_node("MeshInstance").hide()
		# connect("tree_exited", cp, "queue_free")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
