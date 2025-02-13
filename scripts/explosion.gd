extends Node2D

@onready var tilemap = get_node("SpriteTileMap")
@onready var detection_area = get_node("Area2D")

func set_cell_hori(pos: Vector2i, left: int, right: int):
	if pos == Vector2i.ZERO: return
	var edge_tile: Vector2i = Vector2i(0, 2)
	var line_tile: Vector2i = Vector2i(0, 1)
	match pos.x:
		left:
			tilemap.set_cell(pos, 0, edge_tile, 3)
		right:
			tilemap.set_cell(pos, 0, edge_tile, 0)
		_:
			tilemap.set_cell(pos, 0, line_tile, 0)

func set_cell_vert(pos: Vector2i, up: int, down: int):
	if pos == Vector2i.ZERO: return
	var edge_tile: Vector2i = Vector2i(0, 2)
	var line_tile: Vector2i = Vector2i(0, 1)
	match pos.y:
		up:
			tilemap.set_cell(pos, 0, edge_tile, 2)
		down:
			tilemap.set_cell(pos, 0, edge_tile, 1)
		_:
			tilemap.set_cell(pos, 0, line_tile, 1)

func _ready():
	hide()
	detection_area.monitoring = false
	detection_area.monitorable = false
	detection_area.get_child(0).set_deferred("disabled", 1)
	detection_area.get_child(1).set_deferred("disabled", 1)

@rpc("call_local")
func init_detonate(right: int, down: int = right, left: int = right, up: int = right):
	tilemap.clear() #There is probably a smarterway to do this then to do it all over all the time but that might get complex fast 
	tilemap.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO, 0)
	for x in range(-left, right + 1):
		set_cell_hori(Vector2i(x, 0), -left, right)
	for y in range(-up, down + 1):
		set_cell_vert(Vector2i(0, y), -up, down)


	var tile_size: float = tilemap.tile_set.tile_size.x
	detection_area.get_child(0).shape.a = Vector2(-left * tile_size, 0)
	detection_area.get_child(0).shape.b = Vector2(right * tile_size, 0)
	detection_area.get_child(1).shape.a = Vector2(0, - up * tile_size)
	detection_area.get_child(1).shape.b = Vector2(0, down * tile_size)

@rpc("call_local")
func do_detonate():
	show()
	detection_area.monitoring = true
	detection_area.get_child(0).set_deferred("disabled", 0)
	detection_area.get_child(1).set_deferred("disabled", 0)

func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		body.exploded.rpc(get_parent().from_player)	

func _on_area_2d_entered(area: Area2D) -> void:
	if is_multiplayer_authority() && area.has_method("exploded"):
		area.exploded.rpc(get_parent().from_player)	
