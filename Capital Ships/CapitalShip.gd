extends Spatial

func _ready():
	pass

func _process(delta):
	$Label.text = str($HealthSystem.health) + " HP"

func _on_HealthSystem_die() -> void:
	$DestructionTimer.start() # Només activar el timer si es el servidor
	$Alarm.play()

# sync
func _on_DestructionTimer_timeout():
	# take_damage si es el servidor
	queue_free()
