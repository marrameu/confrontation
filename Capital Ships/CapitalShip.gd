extends Spatial

func _ready():
	pass

func _process(delta):
	$Label.text = str($HealthSystem.health) + " HP"

func _on_HealthSystem_die() -> void:
	$DestructionTimer.start()
	$Alarm.play()

func _on_DestructionTimer_timeout():
	queue_free()
