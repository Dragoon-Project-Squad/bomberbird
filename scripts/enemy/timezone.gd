extends StaticBody2D

@onready var hurtbox: CollisionShape2D = get_node("Area2D/hurtbox")
@onready var hitbox: CollisionShape2D = $hitbox
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	stop()
	disable()

func disable():
	hurtbox.set_deferred("disabled", 1)
	hitbox.set_deferred("disabled", 1)
	self.process_mode = Node.PROCESS_MODE_DISABLED

func stop():
	anim.play("disable")
	return

func start() -> Signal:
	self.process_mode = Node.PROCESS_MODE_INHERIT
	show()
	anim.play("deploy")
	return anim.animation_finished

func enable():
	hurtbox.set_deferred("disabled", 0)
	hitbox.set_deferred("disabled", 0)

func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority():
		if body is Player:
			body.exploded.rpc(gamestate.ENEMY_KILL_PLAYER_ID)
		if body is Bomb:
			body.crush()
