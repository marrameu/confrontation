extends Spatial

var moving := false


func _process(delta : float) -> void:
	if not moving:
		$rig/AnimationPlayer.play("man_idle(31)")
	else:
		$rig/AnimationPlayer.play("Man_Run", -1, 0.7)
