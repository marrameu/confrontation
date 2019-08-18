extends CanvasLayer

# Tots els nodes de la nau agafen l'input des d'aquí, millor que l'agafin des del node PlayerInput
var input := Vector2()
var ship_sensitivity := 75.0

var _cursor_visible := false
var _cursor_limit := 450
var _min_position := 20


func _ready() -> void:
	if LocalMultiplayer.number_of_players > 1:
		scale = Vector2(0.5, 0.5)
		
		$Center/CursorPivot/Cursor.rect_scale = Vector2(1.5, 1.5)
		$Center/Crosshair.rect_scale = Vector2(1.5, 1.5)
		$LifeBar.rect_scale = Vector2(2.25, 2.25)
		$Indicators/LeaveIndicator.rect_scale = Vector2(2, 2)
		$Indicators/LandingIndicator.rect_scale = Vector2(2, 2)
		
		# Variable per a la sensibilitat en el mode multijugador, aquesta es multiplica per 2?


func _process(delta : float) -> void:
	if get_tree().has_network_peer():
		if get_parent().is_player:
			if int(get_parent().player_name) != get_tree().get_network_unique_id():
				return
	
	_update_hud_position()
	
	# Debug
	if get_parent().is_player:
		if Input.is_key_pressed(KEY_F1):
			_cursor_visible = true
		elif Input.is_key_pressed(KEY_F2):
			_cursor_visible = false
		
		if not _cursor_visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		_cursor_visible = false
	
	$Center.visible = get_parent().is_player
	
	if get_parent().is_player:
		$Indicators/LeaveIndicator.visible = get_parent().state == get_parent().State.LANDED
		
		if get_parent().state == get_parent().State.FLYING:
			$Indicators/LandingIndicator.visible = get_parent().landing_areas > 0
			$LifeBar.show()
			$LifeBar.value = float(get_node("../HealthSystem").health) / float(get_node("../HealthSystem").MAX_HEALTH) * 100
		else:
			$Indicators/LandingIndicator.hide()
			$LifeBar.hide()
		
	else:
		$Indicators/LeaveIndicator.hide()
		$Indicators/LandingIndicator.hide()
		$LifeBar.hide()


func _physics_process(delta : float) -> void:
	if $Center.visible:
		if LocalMultiplayer.number_of_players == 1 and not Settings.controller_input or get_node("../Input/Player").input_device == -1:
			$Center/CursorPivot/Cursor.rect_position += Utilities.mouse_movement * delta * ship_sensitivity
			$Center/CursorPivot/Cursor.rect_position = $Center/CursorPivot/Cursor.rect_position.clamped(_cursor_limit)
			
			if $Center/CursorPivot/Cursor.rect_position.length() > _min_position:
				input.x = $Center/CursorPivot/Cursor.rect_position.x / _cursor_limit
				input.y = -$Center/CursorPivot/Cursor.rect_position.y / _cursor_limit
			else:
				input = Vector2()
		else:
			$Center/CursorPivot/Cursor.rect_position = Vector2()
			input = Vector2()


func _update_hud_position() -> void:
	if not get_parent().is_player or LocalMultiplayer.number_of_players == 1:
		return
	
	if get_parent().number_of_player == 1:
		offset = Vector2(480, 0)
	elif get_parent().number_of_player == 2:
		offset = Vector2(480, 540)
