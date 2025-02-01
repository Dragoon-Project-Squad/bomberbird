extends Sprite2D

@onready var tilemaplayer = get_node("/root/World/Floor")
@onready var animation = get_node("AnimationPlayer")

var bombowner := 1
var direction = null
# Explosion animation depends on this
enum {CENTER, SIDE, SIDE_BORDER}
var type = CENTER

func _ready():
	await get_tree().process_frame
	# Set the explosion animation depending of it type
	if type == CENTER:
		animation.play("explosion_center")
	elif type == SIDE:
		animation.play("explosion_side")
	else:
		animation.play("explosion_side_border")
	# Only center explosion is symetric, others must be rotated
	# according to there direction
	if direction && direction != Vector2.ZERO:
		rotation = atan2(direction.y, direction.x)

@rpc("call_local")
func double_queue_free():
	queue_free()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	# Explosion finished, we can remove the node
	queue_free()
