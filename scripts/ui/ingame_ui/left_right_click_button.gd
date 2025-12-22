class_name LRClickButton extends SeButton

signal left_click_pressed
signal right_click_pressed

func _init():
	self.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	gui_input.connect(_on_gui_input)
	left_click_pressed.connect(AudioManager.on_button_pressed)
	right_click_pressed.connect(AudioManager.on_button_pressed)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				left_click_pressed.emit()
			MOUSE_BUTTON_RIGHT:
				right_click_pressed.emit()
