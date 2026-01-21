class_name Enemy extends CharacterBody2D

signal enemy_died
signal enemy_health_lost(health: int)

const INVULNERABILITY_TIME: float = 2

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var invul_player: AnimationPlayer = $InvulPlayer
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
@export var health: int = 1:
	set(val):
		enemy_health_lost.emit(val)
		health = val
@export var wallthrought: bool = false
@export var bombthrought: bool = false
@export_group("Multiplayer Variables")
@export var movement_vector = Vector2(0,0)
@export var synced_position := Vector2()
var last_movement_vector: Vector2 = Vector2(1, 0):
	set(val):
		if val.length() == 0: return
		last_movement_vector = val

var current_anim: String = ""
var enemy_path: String = ""
var stunned: bool = false
var invulnerable: bool = false
var stop_moving: bool = false
var time_is_stopped: bool = false
var disabled: bool = false
var _health: int
var _exploded_barrier: bool = false

var invul_timer: SceneTreeTimer

func _ready() -> void:
	assert(detection_handler, "please make sure a detectionhandler is selected for the enemy: " + self.name)
	assert(detection_handler.has_method("check_for_priority_target"), "please make sure the detectionhandler has a method called check_for_priority_target")
	assert(detection_handler.has_method("on"), "please make sure the detectionhandler has a method called on")
	assert(detection_handler.has_method("off"), "please make sure the detectionhandler has a method called off")
	self._health = self.health
	self.disable()
	if self.has_node("DebugMarker"):
		if OS.is_debug_build(): self.get_node("DebugMarker").show()
		else: self.get_node("DebugMarker").hide()


func init_clipping() -> void:
	if self.wallthrought:
		self.set_collision_mask_value(3, false)
	if self.bombthrought:
		self.set_collision_mask_value(4, false)

func _physics_process(_delta):
	# update the animation based on the last known player input state
	last_movement_vector = movement_vector.normalized()
	if stunned || stop_moving: return
	update_animation(movement_vector.normalized(), last_movement_vector)

func update_animation(direction: Vector2, old_direction: Vector2 = Vector2.DOWN):
	var new_anim: String = "standing_down"
	if direction.length() == 0:
		assert(old_direction.length() != 0)
		if old_direction.y < 0:
			new_anim = "standing_up"
		elif old_direction.y > 0:
			new_anim = "standing_down"
		elif old_direction.x < 0:
			new_anim = "standing_left"
		elif old_direction.x > 0:
			new_anim = "standing_right"
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

## starts the invulnerability and its animation
@rpc("call_local")
func do_invulnerability(time: float = INVULNERABILITY_TIME):
	# if there is already a longer invulnerability just leave that be
	if self.invul_timer && self.invul_timer.time_left >= time: return
	# if there is already a shorter invulnerability overwrite it
	elif self.invul_timer: self.invul_timer.timeout.disconnect(stop_invulnerability)
	#if there is no (or a shorter) on write a new invulnerability
	self.invul_timer = get_tree().create_timer(time)
	self.invul_player.play("Invul")
	self.invulnerable = true
	self.invul_timer.timeout.connect(stop_invulnerability)

func stop_invulnerability():
	self.invul_player.stop()
	if self.invul_timer && self.invul_timer.timeout.is_connected(stop_invulnerability):
		self.invul_timer.timeout.disconnect(stop_invulnerability)
	self.invulnerable = false
	self.invul_timer = null

@rpc("call_local")
func do_stun():
	stunned = true
	$AnimationPlayer.play("enemy/stunned")
	await $AnimationPlayer.animation_finished
	stunned = false

@rpc("call_local")
func place(pos: Vector2, path: String):
	if(!is_multiplayer_authority()): return 1
	_exploded_barrier = false
	stop_moving = true
	init_clipping()
	hitbox.set_deferred("disabled", 0)
	self.show()
	self.sprite.show()
	self.anim_player.play("enemy/RESET")
	await anim_player.animation_finished
	self.current_anim = "standing"
	self.movement_vector = Vector2.ZERO
	self.position = pos
	self.enemy_path = path
	stop_moving = false

func enable(with_invul: bool = false):
	self.process_mode = Node.PROCESS_MODE_INHERIT
	self.disabled = false
	self.hurtbox.body_entered.connect(func (player: Player): player.exploded(gamestate.ENEMY_KILL_PLAYER_ID))
	self.detection_handler.on()
	self.statemachine.enable()
	if with_invul: do_invulnerability()

@rpc("call_local")
func exploded(_by_whom: int):
	if(!is_multiplayer_authority()): return 1
	if invulnerable: return 1
	if _exploded_barrier: return
	_exploded_barrier = true
	self.health -= 1
	if self.health_ability:
		self.health_ability.apply()
	if(self.health >= 1):
		do_invulnerability()
		set_process(true)
		_exploded_barrier = false
		return 1
	enemy_died.emit()
	self.statemachine.stop_process = true

	self.anim_player.play("enemy/death")
	disable_hurtbox()
	await self.anim_player.animation_finished
	if globals.game.stage_done: 
		self.hide()
		return
	self.statemachine.stop_process = false
	self.disable()
	globals.game.enemy_pool.return_obj(self)
	_exploded_barrier = false
	
func disable_hurtbox():
	self.hitbox.set_deferred("disabled", 1)
	self.hurtbox.set_deferred("disabled", 1)
	for connection in self.hurtbox.body_entered.get_connections():
		self.hurtbox.body_entered.disconnect(connection.callable)

@rpc("call_local")
func disable():
	if(!is_multiplayer_authority()): return
	self.set_collision_mask_value(3, true)
	self.set_collision_mask_value(4, true)
	self.disabled = true
	if health_ability:
		health_ability.reset()
	self.hide()
	health = _health
	if self.invul_timer: self.invul_timer.timeout.disconnect(stop_invulnerability)
	stop_invulnerability()
	for connection in self.hurtbox.body_entered.get_connections():
		self.hurtbox.body_entered.disconnect(connection.callable)
	for sig_dict in self.enemy_died.get_connections():
		sig_dict.signal.disconnect(sig_dict.callable)
	self.position = Vector2.ZERO
	self.detection_handler.off()
	self.statemachine.disable()
	self.stop_moving = false
	self.time_is_stopped = false
	self.invulnerable = false
	set_process(false)
	self.process_mode = Node.PROCESS_MODE_DISABLED
	self.anim_player.play("enemy/RESET")
	self.current_anim = "standing"
	self.movement_vector = Vector2.ZERO

func stop_time(user: String, is_player: bool):
	if user == self.name && !is_player: return
	self.time_is_stopped = true
	
func start_time():
	self.time_is_stopped = false
