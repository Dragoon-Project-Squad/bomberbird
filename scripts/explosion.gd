extends Node2D

@onready var tilemap = get_node("SpriteTileMap")
@onready var detection_area = get_node("Area2D")

var right
var down
var left
var up

func _ready():
	# For whatever reason collision shapes are by default shared between instances so we need to copy them
	detection_area.get_child(0).shape = detection_area.get_child(0).shape.duplicate(true)
	detection_area.get_child(1).shape = detection_area.get_child(1).shape.duplicate(true)
	reset()

## resets the object s.t. it can be reused at a later time
func reset():
	tilemap.clear()
	detection_area.get_child(0).shape.a = Vector2(-8, 0)
	detection_area.get_child(0).shape.b = Vector2(8, 0)
	detection_area.get_child(1).shape.a = Vector2(0, -8)
	detection_area.get_child(1).shape.b = Vector2(0, 8)
	
	right = 0
	down = 0
	left = 0
	up = 0
	
	hide()
	$AnimationPlayer.stop()
	detection_area.get_child(0).set_deferred("disabled", 1)
	detection_area.get_child(1).set_deferred("disabled", 1)
	process_mode = PROCESS_MODE_DISABLED

## draws all tiles for the horizontal part of the explosion
@warning_ignore("SHADOWED_VARIABLE")
func set_cell_hori(pos: Vector2i, left: int, right: int, step: int = 0):
	if pos == Vector2i.ZERO: return
	var edge_tile: Vector2i = Vector2i(step, 2)
	var line_tile: Vector2i = Vector2i(step, 1)
	match pos.x:
		left:
			tilemap.set_cell(pos, 0, edge_tile, 1)
		right:
			tilemap.set_cell(pos, 0, edge_tile, 0)
		_:
			tilemap.set_cell(pos, 0, line_tile, 0)

## draws all tiles for the vertical part of the explosion
@warning_ignore("SHADOWED_VARIABLE")
func set_cell_vert(pos: Vector2i, up: int, down: int, step: int = 0):
	if pos == Vector2i.ZERO: return
	var edge_tile: Vector2i = Vector2i(step, 2)
	var line_tile: Vector2i = Vector2i(step, 1)
	match pos.y:
		up:
			tilemap.set_cell(pos, 0, edge_tile, 3)
		down:
			tilemap.set_cell(pos, 0, edge_tile, 2)
		_:
			tilemap.set_cell(pos, 0, line_tile, 1)

## sets up all values for the explosition that the bomb calculated.
@rpc("call_local")
@warning_ignore("SHADOWED_VARIABLE")
func init_detonate(right: int, down: int = right, left: int = right, up: int = right):
	self.right = right
	self.down = down
	self.left = left
	self.up = up

	next_detonate()
	var tile_size: float = tilemap.tile_set.tile_size.x
	if left > 0:
		detection_area.get_child(0).shape.a = Vector2(-left * tile_size, 0)
	if right > 0:
		detection_area.get_child(0).shape.b = Vector2(right * tile_size, 0)
	if up > 0:
		detection_area.get_child(1).shape.a = Vector2(0, - up * tile_size)
	if down > 0:
		detection_area.get_child(1).shape.b = Vector2(0, down * tile_size)

## Gets called once by init_detonate and then from an animation with increasing steps
func next_detonate(step: int = 0):
	tilemap.set_cell(Vector2i.ZERO, 0, Vector2i(step, 0), 0)
	for x in range(-left, right + 1):
		set_cell_hori(Vector2i(x, 0), -left, right, step)
	for y in range(-up, down + 1):
		set_cell_vert(Vector2i(0, y), -up, down, step)

## Starts the detonation. Must be called after init_detonate(...)
@rpc("call_local")
func do_detonate():
	show()
	$AnimationPlayer.play("boom") #this animation is freaky ngl
	process_mode = PROCESS_MODE_INHERIT
	detection_area.get_child(0).set_deferred("disabled", 0)
	detection_area.get_child(1).set_deferred("disabled", 0)
	await $AnimationPlayer.animation_finished
	get_parent().done()

## reports a kill from a player to the killer s.t. he can be revived if the settings allow it
func report_kill(killed_player: Player):
	var killer: Player = get_parent().bomb_root.bomb_owner
	if !is_multiplayer_authority(): return
	killer.misobon_player.revive.rpc(killed_player.position)
	
func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		if self not in body.get_children():
			body.exploded.rpc(str(get_parent().bomb_root.bomb_owner.name).to_int())
	if (
		body is Player
		&& get_parent().bomb_root.bomb_owner_is_dead #was the bomb owner dead when the bomb was created?
		&& get_parent().bomb_root.bomb_owner.is_dead #is the bomb owner still dead?
		&& body.lives - 1 <= 0 #will the player that got hit die
		&& !body.stunned #will the player that got hit die
		&& !body.invulnerable #will the player that got hit die
		&& !body.hurry_up_started #has hurry up alread started
	): #TODO: fix this, this is stupit
		report_kill(body)

func _on_area_2d_entered(area: Area2D) -> void:
	if is_multiplayer_authority() && area.has_method("exploded"):
		area.exploded.rpc(str(get_parent().bomb_root.bomb_owner.name).to_int())
