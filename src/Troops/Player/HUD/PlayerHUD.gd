extends CanvasLayer

# Life Bars
var ray_range := 25.0
var camera_width_center := 0.0
var camera_height_center := 0.0
var shoot_origin := Vector3()
var shoot_normal := Vector3()
var life_bar : TextureProgress = preload("res://src/Troops/Player/HUD/LifeBar.tscn").instance()
var target : Spatial

func _ready() -> void:
	add_child(life_bar)
	life_bar.hide()

func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if not is_network_master():
			$PlayerLifeBar.hide()
			$Nickname.hide()
			life_bar.hide()
			return
			# queue_free()
	
	# Life Bars
	var m_health_system = get_parent().get_node("HealthSystem")
	if m_health_system.health == 0 or get_node("../Interaction").is_in_a_vehicle:
		$PlayerLifeBar.hide()
		$Nickname.hide()
		life_bar.hide()
		return
	else:
		$PlayerLifeBar.value = float(m_health_system.health) / float(m_health_system.MAX_HEALTH) * 100
		$PlayerLifeBar.show()
		if LocalMultiplayer.number_of_players == 2:
			$PlayerLifeBar.rect_position = Vector2(897.5, 460)
		elif LocalMultiplayer.number_of_players > 2:
			$PlayerLifeBar.rect_position = Vector2(448.75, 460)
	
	var current_cam : Camera = get_node("/root/Main").players_cameras[get_parent().number_of_player - 1].troop_camera
	var space_state = get_parent().get_world().direct_space_state
	
	if current_cam:
		var viewport = get_node("/root/Main/Splitscreen")._renders[get_parent().number_of_player - 1].viewport
		camera_width_center = viewport.get_visible_rect().size.x / 2
		camera_height_center = viewport.get_visible_rect().size.y / 2
		
		shoot_origin = current_cam.project_ray_origin(Vector2(camera_width_center, camera_height_center))
		shoot_normal = shoot_origin + current_cam.project_ray_normal(Vector2(camera_width_center, camera_height_center)) * ray_range
		
		var result = space_state.intersect_ray(shoot_origin, shoot_normal, [get_parent()], 2)
		if result:
			if result.collider.is_in_group("Players") or result.collider.is_in_group("Troops"):
				target = result.collider
				if result.collider.get_node("TroopManager").m_team == get_node("../TroopManager").m_team:
					(life_bar as TextureProgress).tint_progress = Color("96006aff")
				else:
					(life_bar as TextureProgress).tint_progress = Color("96ff0000")
				
				$Nickname.text = result.collider.nickname
				if result.collider.get_node("TroopManager").m_team == get_node("../TroopManager").m_team:
					$Nickname.add_color_override("font_color", "72a9ff")
				else:
					$Nickname.add_color_override("font_color", "ff7272")
				
				life_bar.show()
				$Nickname.show()
				$LifeBarTimer.start()
	
	if target:
		if not current_cam.is_position_behind(target.translation) and target.translation.distance_to(get_parent().translation) <= ray_range:
			if target.get_node("HealthSystem").health == 0:
				life_bar.value = (float(target.get_node("HealthSystem").health) / float(target.get_node("HealthSystem").MAX_HEALTH)) * 100
				life_bar.hide()
				$Nickname.hide()
				target = null
				return
			life_bar.show()
			life_bar.value = (float(target.get_node("HealthSystem").health) / float(target.get_node("HealthSystem").MAX_HEALTH)) * 100
			life_bar.rect_position = (current_cam as Camera).unproject_position(target.translation + Vector3(0, 2, 0)) - Vector2(life_bar.rect_size.x / 2, life_bar.rect_size.y / 2)
			$Nickname.rect_position = (current_cam as Camera).unproject_position(target.translation + Vector3(0, 2, 0)) - Vector2($Nickname.rect_size.x / 2, $Nickname.rect_size.y / 2) - Vector2(0, 50)
		else:
			life_bar.hide()
			$Nickname.hide()

func _on_LifeBarTimer_timeout():
	life_bar.hide()
	$Nickname.hide()
	target = null
