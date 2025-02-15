class_name Pickup extends Area2D
@onready var pickup_sfx : AudioStreamWAV = load("res://sound/fx/powerup.wav")
@onready var pickup_sfx_player = $PickupSoundPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var collisionbox : CollisionShape2D = $CollisionShape2D
var pickup_owner : Node2D = null

func _ready():
	pass
	#pickup_sfx_player.set_stream(pickup_sfx)

@rpc("call_local")
func hide_and_disable():
	collisionbox.visible = false
	collisionbox.queue_free()
	animated_sprite.visible = false
	animated_sprite.queue_free()

func _on_body_entered(_body: Node2D) -> void:
	pass

@rpc("call_local")
func exploded(_from_player):
	collisionbox.queue_free()
	if $anim:
		$anim.play("explode_pickup")
		await $anim.animation_finished
	queue_free()
