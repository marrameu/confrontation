extends Node

func _on_Timer_timeout() -> void:
	(self as Node).queue_free()