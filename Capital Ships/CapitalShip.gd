extends Spatial
class_name CapitalShip


func _ready() -> void:
	pass


func _process(delta : float) -> void:
	$Label.text = str($HealthSystem.health) + " HP"


func _on_HealthSystem_die() -> void:
	$Alarm.play()
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	$DestructionTimer.start()


func _on_DestructionTimer_timeout() -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			rpc("explode")
	else:
		explode()


sync func explode() -> void:
	# Anim 
	queue_free()
