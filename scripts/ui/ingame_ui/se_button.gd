class_name SeButton extends Button

func _init():
	self.connect("pressed", func(): AudioManager.on_button_pressed())
