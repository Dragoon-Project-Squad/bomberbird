class_name Enemy extends CharacterBody2D

signal enemy_died

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var statemachine: Node = $StateMachine
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

@export_group("Enemy Settings")
@export var movement_speed: float = 30.0
@export var detection_handler: Node2D
@export_group("Multiplayer Variables")
@export var movement_vector = Vector2(0,0)
@export var synced_position := Vector2()

var current_anim: String = ""
var enemy_path: String = ""
var stunned: bool = false

func _ready() -> void:
	assert(detection_handler, "please make sure a detectionhandler is selected for the enemy: " + self.name)
	assert(detection_handler.has_method("check_for_priority_target"), "please make sure the detectionhandler has a method called check_for_priority_target")
	assert(detection_handler.has_method("on"), "please make sure the detectionhandler has a method called on")
	assert(detection_handler.has_method("off"), "please make sure the detectionhandler has a method called off")
	self.disable()

func _physics_process(_delta):
	# update the animation based on the last known player input state
	if stunned: return
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
		$AnimationPlayer.play("enemy/" + current_anim)

func do_stun():
	stunned = true
	$AnimationPlayer.play("enemy/stunned")
	await $AnimationPlayer.animation_finished
	stunned = false

@rpc("call_local")
func place(pos: Vector2, path: String):
	if(!is_multiplayer_authority()): return 1
	await get_tree().create_timer(0.2).timeout
	hitbox.set_deferred("disabled", 0)
	self.show()
	self.anim_player.play("enemy/standing")
	self.position = pos
	self.enemy_path = path

func enable():
	self.hurtbox.body_entered.connect(func (player: Player): player.exploded(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID))
	self.detection_handler.on()
	self.statemachine.enable()

@rpc("call_local")
func exploded(_by_whom: int):
	if(!is_multiplayer_authority()): return 1
	enemy_died.emit()
	self.disable()
	
@rpc("call_local")
func disable():
	if(!is_multiplayer_authority()): return 1
	hitbox.set_deferred("disabled", 1)
	hide()
	for connection in self.hurtbox.body_entered.get_connections():
		self.hurtbox.body_entered.disconnect(connection.callable)
	self.position = Vector2.ZERO
	self.detection_handler.off()
	self.statemachine.disable()
