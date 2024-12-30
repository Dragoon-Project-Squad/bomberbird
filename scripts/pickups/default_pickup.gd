class_name Pickup extends Area2D
@onready var pickup_sfx : AudioStreamWAV = load("res://sound/fx/powerup.wav")
@onready var pickup_sfx_player = $PickupSoundPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var collisionbox : CollisionShape2D = $CollisionShape2D
var pickup_owner : Node2D = null

func _ready():
	pickup_sfx_player.set_stream(pickup_sfx)

func hide_and_disable():
	collisionbox.visible = false
	collisionbox.queue_free()
	animated_sprite.visible = false
	animated_sprite.queue_free()
