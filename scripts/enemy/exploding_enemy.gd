extends Enemy

const EXPLOSION_WIDTH: int = 2
const TILE_SIZE: int = 32
const LIVETIME: float = 13

@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player: AudioStreamPlayer2D #Left 2D for Monsto fix
@onready var rays: Node2D = $Raycasts
@onready var explosion: Explosion = $Explosion

func _ready() -> void:
	explosion_sfx_player = globals.game.bomb_pool.get_node("BombGlobalAudioPlayers/ExplosionSoundPlayer")
	explosion_sfx_player.set_stream(explosion_audio)
	self.explosion.is_finished_exploding.connect(done)
	self.explosion.has_killed.connect(_kill)
	self.set_process(false)
	super()

@rpc("call_local")
func exploded(_by_whom: int):
	if(!is_multiplayer_authority()): return 1
	if invulnerable || damage_invulnerable: return 1
	if _exploded_barrier: return
	_exploded_barrier = true
	self.statemachine.stop_process = true
	self.sprite.hide()
	self.position = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.position))
	explosion_sfx_player.stop()
	explosion_sfx_player.position = self.position #Monsto Fix
	explosion_sfx_player.play()
	var exp_range = {
		Vector2i.RIGHT: EXPLOSION_WIDTH,
		Vector2i.DOWN: EXPLOSION_WIDTH,
		Vector2i.LEFT: EXPLOSION_WIDTH,
		Vector2i.UP: EXPLOSION_WIDTH 
		}
	for ray: RayCast2D in rays.get_children():
		var ray_direction = ray.get_meta("direction")
		ray.target_position = ray_direction * EXPLOSION_WIDTH * TILE_SIZE
		ray.force_raycast_update()
		if !ray.is_colliding():
			continue
		var target: Node2D = ray.get_collider()
		if target.is_in_group("bombstop"):
			@warning_ignore("INTEGER_DIVISION") # Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
			var col_point = to_local(ray.get_collision_point()) + Vector2(ray_direction * (TILE_SIZE / 2))
			# find the distance from bomb.position to the last tile that should be blown up (in number of tiles)
			exp_range[ray_direction] = explosion.get_node("SpriteTileMap").local_to_map(col_point).length() - 1 
			if target.has_method("exploded") && is_multiplayer_authority():
				target.exploded.rpc(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID) # if an object stopped the bomb and can be blown up... blow it up!
	if is_multiplayer_authority(): # multiplayer auth. now starts the transition to the explosion
		explosion.init_detonate.rpc(exp_range[Vector2i.RIGHT], exp_range[Vector2i.DOWN], exp_range[Vector2i.LEFT], exp_range[Vector2i.UP])
		explosion.do_detonate.rpc()

func done():
	_exploded_barrier = false
	enemy_died.emit()
	self.disable()
	globals.game.enemy_pool.return_obj(self)

@rpc("call_local")
func disable():
	super()
	self.sprite.show()
	self.explosion.reset()
	self.statemachine.stop_process = false

func _kill(obj):
	obj.exploded.rpc(gamestate.ENEMY_KILL_PLAYER_ID)
