extends Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.connect(_on_timeout)
	
func _on_timeout():
	%RemainingTime.add_theme_color_override("font_color", Color(255, 0, 0))
	get_tree().get_root().get_node("World/Timers/RestrictionTimer").start()
