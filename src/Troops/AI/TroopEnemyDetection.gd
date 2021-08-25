extends Node

var enemies := []


func _ready() -> void:
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			set_process(false)


func _process(_delta):
	if owner.get_node("TroopManager").m_team == 0:
		return
	
	enemies = []
	for body in $Area.get_overlapping_bodies():
		if body.is_in_group("Troops"):
			var troop_manager : Node = body.get_node("TroopManager")
			if troop_manager:
				if troop_manager.m_team != get_parent().get_node("TroopManager").m_team:
					var health_system : Node = body.get_node("HealthSystem")
					if health_system.health > 0:
						enemies.push_back(body)
	
	if enemies.size() > 0 and not get_parent().current_enemie:
		get_parent().current_enemie = enemies[0]
	if get_parent().current_enemie:
		if get_parent().current_enemie.translation.distance_to(get_parent().translation) > 30:
			get_parent().current_enemie = null


func set_active(value):
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	$Area/CollisionShape.disabled = !value
	set_process(value) # No caldria
	enemies = []
