extends VBoxContainer


func _ready() -> void:
	$Controls/Sliders/HSliderMouse.value = Settings.mouse_sensitivity * 100
	$Controls/Sliders/HSliderJoystick.value = Settings.joystick_sensitivity * 100
	$Others/SpinBox.value = Settings.fov


func _process(delta : float) -> void:
	if Settings.quality == 0:
		$Graphics/Buttons/ButtonLow.add_color_override("font_color", Color("b4c7dc"))
		$Graphics/Buttons/ButtonMiddle.add_color_override("font_color", Color.white)
		$Graphics/Buttons/ButtonHigh.add_color_override("font_color", Color.white)
	elif Settings.quality == 1:
		$Graphics/Buttons/ButtonMiddle.add_color_override("font_color", Color("b4c7dc"))
		$Graphics/Buttons/ButtonLow.add_color_override("font_color", Color.white)
		$Graphics/Buttons/ButtonHigh.add_color_override("font_color", Color.white)
	elif Settings.quality == 2:
		$Graphics/Buttons/ButtonHigh.add_color_override("font_color", Color("b4c7dc"))
		$Graphics/Buttons/ButtonMiddle.add_color_override("font_color", Color.white)
		$Graphics/Buttons/ButtonLow.add_color_override("font_color", Color.white)


func _on_GraphicsButton_pressed(quality : int) -> void:
	Utilities.play_button_audio()
	Settings.quality = quality
	Settings.save_settings()


func _on_HSliderJoystick_value_changed(value : float) -> void:
	Settings.joystick_sensitivity = float(value / 100)
	Settings.save_settings()


func _on_HSliderMouse_value_changed(value : float) -> void:
	Settings.mouse_sensitivity = float(value / 100)
	Settings.save_settings()


func _on_SensitivityDefaultsButton_pressed() -> void:
	Utilities.play_button_audio()
	$Controls/Sliders/HSliderMouse.value = 75
	$Controls/Sliders/HSliderJoystick.value = 60


func _on_SpinBox_value_changed(value : float):
	Settings.fov = int(value)
	Settings.save_settings()


func _on_FovDefaultsButton_pressed() -> void:
	Utilities.play_button_audio()
	$Others/SpinBox.value = 70
