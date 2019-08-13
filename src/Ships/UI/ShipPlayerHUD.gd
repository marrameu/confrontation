extends CanvasLayer

var mouse_position := Vector2()

var cursor_visible := false

func _ready() -> void:
	if LocalMultiplayer.number_of_players > 1:
		scale = Vector2(0.5, 0.5)
		
		$ShipUI/Control/Cursor.rect_scale = Vector2(1.5, 1.5)
		$Crosshair.rect_scale = Vector2(1.5, 1.5)
		$LifeBar.rect_scale = Vector2(2.25, 2.25)
		$LeaveIndicator.rect_scale = Vector2(2, 2)
		$LandingIndicator.rect_scale = Vector2(2, 2)


func _process(delta : float):
	if get_tree().has_network_peer():
		if get_parent().is_player:
			if int(get_parent().player_name) != get_tree().get_network_unique_id():
				return
	
	update_hud_position()
	
	if Input.is_key_pressed(KEY_F1):
		cursor_visible = true
	elif Input.is_key_pressed(KEY_F2):
		cursor_visible = false
	
	if get_parent().is_player:
		$Crosshair.show()
		if LocalMultiplayer.number_of_players == 1:
			if not Settings.controller_input:
				$ShipUI.show()
			else:
				$ShipUI.hide()
		else:
			if get_node("../Input/Player").input_device == -1:
				$ShipUI.show()
			else:
				$ShipUI.hide()
		
		if not cursor_visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		$Crosshair.hide()
		$ShipUI.hide()
		cursor_visible = false
	
	if get_parent().landing_areas > 0 and get_parent().state == 1 and get_parent().is_player:
		$LandingIndicator.show()
	else:
		$LandingIndicator.hide()
	
	if get_parent().state == 0 and get_parent().is_player:
		$LeaveIndicator.show()
	else:
		$LeaveIndicator.hide()
	
	if get_parent().is_player and get_parent().state == 1:
		$LifeBar.show()
		var m_health_system = get_node("../HealthSystem")
		$LifeBar.value = float(m_health_system.health) / float(m_health_system.MAX_HEALTH) * 100
	else:
		$LifeBar.hide()

func _input(event):
	if event is InputEventMouseMotion:
		mouse_position = event.position

func update_hud_position() -> void:
	if not get_parent().is_player or LocalMultiplayer.number_of_players == 1:
		return
	
	# 2P Màxim per ara
	if get_parent().number_of_player == 1:
		offset = Vector2(480, 0)
	elif get_parent().number_of_player == 2:
		offset = Vector2(480, 540)
