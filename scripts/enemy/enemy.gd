class_name Enemy extends CharacterBody2D

signal enemy_died

const INVULNERABILITY_TIME: float = 2
const INVULNERABILITY_FLASH_TIME: float = 0.125

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var statemachine: Node = $StateMachine
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite := $sprite

@export_group("Enemy Settings")
@export var score_points: int = 100
@export var movement_speed: float = 30.0
@export var detection_handler: Node
@export var health_ability: Node
@export var animation_sub: String = "enemy"
@export var health: int = 1
@export var wallthrought: bool = false
@export var bombthrought: bool = false
@export_group("Multiplayer Variables")
@export var movement_vector = Vector2(0,0)
@export var synced_position := Vector2()

var current_anim: String = ""
var enemy_path: String = ""
var stunned: bool = false
var invulnerable: bool = false
var damage_invulnerable: bool = false
var stop_moving: bool = false
var _health: int

var invulnerable_animation_time: float = 0
var invulnerable_remaining_time: float = 0

func _ready() -> void:
	assert(detection_handler, "please make sure a detectionhandler is selected for the enemy: " + self.name)
	assert(detection_handler.has_method("check_for_priority_target"), "please make sure the detectionhandler has a method called check_for_priority_target")
	assert(detection_handler.has_method("on"), "please make sure the detectionhandler has a method called on")
	assert(detection_handler.has_method("off"), "please make sure the detectionhandler has a method called off")
	self._health = self.health
	self.disable()

func _process(delta: float):
	if !damage_invulnerable:
		show()
		set_process(false)
		return
	invulnerable_remaining_time -= delta
	invulnerable_animation_time += delta
	if invulnerable_remaining_time <= 0:
		damage_invulnerable = false
	elif invulnerable_animation_time <= INVULNERABILITY_FLASH_TIME:
		self.visible = !self.visible
		invulnerable_animation_time = 0

func _physics_process(_delta):
	# update the animation based on the last known player input state
	if stunned || stop_moving: return
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
		$AnimationPlayer.play(animation_sub + "/" + current_anim)

func do_stun():
	stunned = true
	$AnimationPlayer.play("enemy/stunned")
	await $AnimationPlayer.animation_finished
	stunned = false

@rpc("call_local")
func place(pos: Vector2, path: String):
	if(!is_multiplayer_authority()): return 1
	self.anim_player.play("enemy/RESET")
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
	if invulnerable || damage_invulnerable: return 1
	if(self.health > 1):
		invulnerable_remaining_time = INVULNERABILITY_TIME
		damage_invulnerable = true
		set_process(true)
		self.health -= 1
		if self.health_ability:
			self.health_ability.apply()
		return 1
	enemy_died.emit()
	self.statemachine.stop_process = true
	self.anim_player.play("enemy/death")
	await self.anim_player.animation_finished
	self.statemachine.stop_process = false
	self.disable()
	globals.game.enemy_pool.return_obj(self)
	
@rpc("call_local")
func disable():
	if(!is_multiplayer_authority()): return 1
	if health_ability:
		health_ability.reset()
	set_process(false)
	hitbox.set_deferred("disabled", 1)
	self.hide()
	health = _health
	for connection in self.hurtbox.body_entered.get_connections():
		self.hurtbox.body_entered.disconnect(connection.callable)
	self.position = Vector2.ZERO
	self.detection_handler.off()
	self.statemachine.disable()
