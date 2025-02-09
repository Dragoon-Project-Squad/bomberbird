extends Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.connect(_on_timeout)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_timeout():
	get_tree().get_root().get_node("World/Timers/RestrictionTimer").start()
