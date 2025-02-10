extends Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.connect(_on_timeout)
	
func _on_timeout():
	get_tree().get_root().get_node("World/Timers/RestrictionTimer").start()
