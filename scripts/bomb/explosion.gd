class_name Explosion extends Node2D

signal is_finished_exploding
signal has_killed

@onready var tilemap: TileMapLayer = $SpriteTileMap
@onready var detection_area: Area2D = $Area2D

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

func set_cell_hori(pos: Vector2i, cell_left: int, cell_right: int, step: int = 0):
	if pos == Vector2i.ZERO: return
	var edge_tile: Vector2i = Vector2i(step, 2)
	var line_tile: Vector2i = Vector2i(step, 1)
	match pos.x:
		cell_left:
			tilemap.set_cell(pos, 0, edge_tile, TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V)
		cell_right:
			tilemap.set_cell(pos, 0, edge_tile, 0)
		_:
			tilemap.set_cell(pos, 0, line_tile, 0)

## draws all tiles for the vertical part of the explosion

func set_cell_vert(pos: Vector2i, cell_up: int, cell_down: int, step: int = 0):
	if pos == Vector2i.ZERO: return
	var edge_tile: Vector2i = Vector2i(step, 2)
	var line_tile: Vector2i = Vector2i(step, 1)
	match pos.y:
		cell_up:
			tilemap.set_cell(pos, 0, edge_tile, TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V)
		cell_down:
			tilemap.set_cell(pos, 0, edge_tile, TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H)
		_:
			tilemap.set_cell(pos, 0, line_tile, TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H)

## sets up all values for the explosition that the bomb calculated.
@rpc("call_local")
func init_detonate(right_score: int, down_score: int = right, left_score: int = right, up_score: int = right):
	self.right = right_score
	self.down = down_score
	self.left = left_score
	self.up = up_score

	next_detonate()
	var tile_size: float = tilemap.tile_set.tile_size.x
	if left > 0:
		detection_area.get_child(0).shape.a = Vector2(-left * tile_size, 0)
	if right > 0:
		detection_area.get_child(0).shape.b = Vector2(right * tile_size, 0)
	if up > 0:
		detection_area.get_child(1).shape.a = Vector2(0, -up * tile_size)
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
	self.is_finished_exploding.emit()

	
func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		has_killed.emit(body)

func _on_area_2d_entered(area: Area2D) -> void:
	if is_multiplayer_authority() && area.has_method("exploded"):
		has_killed.emit(area)
