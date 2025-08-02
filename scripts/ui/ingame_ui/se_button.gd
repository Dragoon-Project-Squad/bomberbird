class_name SeButton extends Button

func _init():
	self.pressed.connect(AudioManager.on_button_pressed)
