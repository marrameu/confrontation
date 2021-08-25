extends "OnFloor.gd"


export(NodePath) var CONQUEST_TIMER
onready var conquest_timer : Timer = get_node(CONQUEST_TIMER)


func _ready():
	assert(CONQUEST_TIMER)
	conquest_timer.connect("timeout", self, "_on_ConquestTimer_timeout")


func enter():
	conquest_timer.wait_time = rand_range(7.0, 13.0) # millor, en lloc de temps, senyal quan s'ha conquerit el post
	conquest_timer.start()
	owner.get_node("PlayerMesh/rig/AnimationPlayer").play("man_idle(31)")


func _on_ConquestTimer_timeout():
	emit_signal("finished", "go_to_cp")


func _on_animation_finished(anim_name):
	if anim_name == "man_idle(31)":
		owner.get_node("PlayerMesh/rig/AnimationPlayer").play("man_idle(31)", -1, 0.7)


func exit():
	conquest_timer.stop()
