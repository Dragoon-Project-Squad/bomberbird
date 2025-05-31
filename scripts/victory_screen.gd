extends Node2D
@onready var fade_in_out: AnimationPlayer = $AnimPlayer


func _ready() -> void:
	fade_in_out.play("fade_in")
