class_name Enemy extends CharacterBody2D


@onready var anim_player = $AnimationPlayer
@onready var detection_handler = $DetectionHandler
@onready var statemachine = $StateMachine
@onready var hitbox = $Hitbox

@export_group("Enemy Settings")
@export var movement_speed: float = 50.0
@export_group("Multiplayer Variables")
@export var movement_vector = Vector2(0,0)
@export var synced_position := Vector2()

var current_anim: String = ""
var enemy_path: String = ""

func _ready() -> void:
	self.disable()

func _physics_process(delta):
	statemachine.current_state._physics_update(delta)
	# Also update the animation based on the last known player input state
	update_animation(movement_vector.normalized())

func update_animation(direction: Vector2):
	var new_anim: String = "standing"
	if direction.length() == 0:
		new_anim = "standing"
	elif direction.y < 0:
		new_anim = "walk_up"
	elif direction.y > 0:
		new_anim = "walk_down"
	elif direction.x < 0:
		new_anim = "walk_left"
	elif direction.x > 0:
		new_anim = "walk_right"
		
	if new_anim != current_anim:
		current_anim = new_anim
		$AnimationPlayer.play("base_enemy/" + current_anim)

@rpc("call_local")
func place(pos: Vector2, path: String):
	if(!is_multiplayer_authority()): return 1
	hitbox.set_deferred("disabled", 0)
	self.show()
	self.anim_player.play("base_enemy/standing")
	self.position = pos
	self.enemy_path = path
	self.detection_handler.on()
	self.statemachine.enable()

@rpc("call_local")
func exploded(_by_whom: int):
	if(!is_multiplayer_authority()): return 1
	self.disable()
	
@rpc("call_local")
func disable():
	if(!is_multiplayer_authority()): return 1
	print("disabled")
	hitbox.set_deferred("disabled", 1)
	hide()
	self.position = Vector2.ZERO
	self.detection_handler.off()
	self.statemachine.disable()
