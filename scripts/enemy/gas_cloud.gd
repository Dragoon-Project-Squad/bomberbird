extends Enemy
# The gas cloud is a special enemy that usually just appears as a summon

const EXPLOSION_WIDTH: int = 2
const TILE_SIZE: int = 32
const LIFETIME: float = 13

@onready var rays: Node2D = $Raycasts
@onready var explosion: Explosion = $Explosion
@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	self.explosion.is_finished_exploding.connect(done)
	self.explosion.has_killed.connect(_kill)
	self.life_timer.one_shot = true
	self.set_process(false)
	super()

func _physics_process(_delta):
	pass

func do_stun():
	pass

@rpc("call_local")
func exploded(_by_whom: int):
	if(!is_multiplayer_authority()): return 1
	if invulnerable || damage_invulnerable: return 1
	if _exploded_barrier: return
	_exploded_barrier = true
	self.statemachine.stop_process = true
	self.sprite.hide()
	self.position = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.position))
	
	#Apparently, this enemy is supposed to explode, so here I call the explosion sound event
	Wwise.post_event("snd_bomb_explode", self)
	
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

func _lifetime_over():
	if _exploded_barrier: return
	_exploded_barrier = true
	done()

@rpc("call_local")
func place(pos: Vector2, path: String):
	if(!is_multiplayer_authority()): return 1
	hitbox.set_deferred("disabled", 0)
	self.show()
	sprite.play()
	print(pos)
	self.position = pos
	self.enemy_path = path
	life_timer.start(LIFETIME)
	life_timer.timeout.connect(_lifetime_over, CONNECT_ONE_SHOT)

@rpc("call_local")
func disable():
	self.disabled = true
	if health_ability:
		health_ability.reset()
	self.hide()
	health = _health
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
	self.movement_vector = Vector2.ZERO

	sprite.stop()
	self.sprite.show()
	self.explosion.reset()
	life_timer.stop()
	if life_timer.timeout.has_connections():
		life_timer.timeout.disconnect(_lifetime_over)
	self.statemachine.stop_process = false

func _kill(obj):
	obj.exploded.rpc(gamestate.ENEMY_KILL_PLAYER_ID)
