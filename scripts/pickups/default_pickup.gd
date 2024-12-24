class_name Pickup extends Area2D
@onready var pickup_sfx = load("res://sound/fx/powerup.wav")
@onready var pickup_sfx_player := $PickupSound
@onready var animated_sprite = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pickup_sfx_player.set_stream(pickup_sfx)
	animated_sprite.play("idle")
