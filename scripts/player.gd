class_name Player extends CharacterBody2D

const BASE_MOTION_SPEED: float = 100.0
const BOMB_RATE: float = 0.5
const MAX_BOMBS_OWNABLE: int = 8
const MAX_EXPLOSION_BOOSTS_PERMITTED: int = 6
const MISOBON_RESPAWN_TIME: float = 0.5

@export var synced_position := Vector2()
@export var stunned: bool = false

@onready var hurt_sfx_player := $HurtSoundPlayer

var current_anim: String = ""
var is_dead: bool = false
var player_type: String

var bomb_pool: ObjectPool
var last_bomb_time: float = BOMB_RATE
var bomb_total: int

@export_subgroup("player properties") #Set in inspector
@export var movement_speed: float = BASE_MOTION_SPEED
@export var bomb_count: int
@export var lives: int
@export var explosion_boost_count: int
@export var can_punch: bool

var tile_map: TileMapLayer

func _ready():
	#These are all needed
	position = synced_position
	bomb_total = bomb_count
	tile_map = get_parent().get_parent().get_node("Floor")
	bomb_pool = get_node("/root/World/BombPool")

func _physics_process(_delta: float):
	pass

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
		$AnimationPlayer.play(current_anim)

func enter_misobon():
	if(!has_node("/root/MainMenu") && get_node("/root/Lobby").curr_misobon_state == 0):
			#in singlayer always just have it on SUPER for now (until we have options in sp) and in multiplayer spawn misobon iff its not off
		return

	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	if is_multiplayer_authority():
		get_node("../../MisobonPlayerSpawner").spawn({
		"player_type": player_type,
		"spawn_here": get_node("../../MisobonPath").get_progress_from_vector(synced_position),
		"pid": str(name).to_int(),
		"name": get_player_name()
		}).play_spawn_animation()

func enter_death_state():
	$AnimationPlayer.play("death")
	await $AnimationPlayer.animation_finished
	process_mode = PROCESS_MODE_DISABLED
	
func exit_death_state():
	self.visible = true #Visible
	process_mode = PROCESS_MODE_INHERIT

func set_player_name(value):
	$label.set_text(value)

func get_player_name() -> String:
	return $label.get_text()
	
@rpc("call_local")
func increase_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 1, MAX_EXPLOSION_BOOSTS_PERMITTED)
	
@rpc("call_local")
func maximize_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 99, MAX_EXPLOSION_BOOSTS_PERMITTED)
	
@rpc("call_local")
func increase_speed():
	movement_speed = movement_speed + 20

@rpc("call_local")
func increment_bomb_count():
	bomb_total = min(bomb_total+1, MAX_BOMBS_OWNABLE)
	bomb_count = min(bomb_count+1, bomb_total)
	

@rpc("call_local")
func return_bomb():
	bomb_count = min(bomb_count+1, bomb_total)

@rpc("call_local")
func enable_punch():
	can_punch = true

@rpc("call_local")
func exploded(by_who):
	if stunned:
		return
	stunned = true
	lives -= 1
	hurt_sfx_player.play()
	if by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID && str(by_who) == name: 
		$"../../GameUI".decrease_score(by_who) # Take away a point for blowing yourself up
	elif by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID:
		$"../../GameUI".increase_score(by_who) # Award a point to the person who blew you up
		#TODO notify other player of kill
	if lives <= 0:
		is_dead = true
		#TODO: Knockout Player
		enter_death_state()
		enter_misobon()
	else:
		$AnimationPlayer.play("stunned")

func set_selected_character(value: Texture2D):
	$sprite.texture = value
