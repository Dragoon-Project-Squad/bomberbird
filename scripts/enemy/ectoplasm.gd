extends CharacterBody2D

const max_range = 3

signal ectopasm_finished 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Area2D

@export var synced_position: Vector2
@export var movement_speed: float = 16

var dir: Vector2

func _ready():
	disable()

func _physics_process(_delta: float) -> void:
	#Update position
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		self.synced_position = self.position
	else:
		self.position = self.synced_position
	
	# Also update the animation based on the last known player input state
	velocity = self.dir.normalized() * self.movement_speed
	move_and_slide()

func disable() -> void:
	hide()
	set_deferred("disabled", 1)
	self.position = Vector2.ZERO
	self.process_mode = Node.PROCESS_MODE_DISABLED
	ectopasm_finished.emit()

func start(direction: Vector2) -> Signal:
	self.dir = direction
	show()
	set_deferred("disabled", 0)
	self.process_mode = Node.PROCESS_MODE_INHERIT
	return ectopasm_finished 

func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		if self not in body.get_children():
			body.exploded.rpc(gamestate.ENEMY_KILL_PLAYER_ID)
