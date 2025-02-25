extends Node2D

@onready var tilemap = get_node("SpriteTileMap")
@onready var detection_area = get_node("Area2D")

var right
var down
var left
var up

func reset():
	tilemap.clear() #There is probably a smarterway to do this then to do it all over all the time but that might get complex fast 
	detection_area.get_child(0).shape.a = Vector2(-16, 0)
	detection_area.get_child(0).shape.b = Vector2(16, 0)
	detection_area.get_child(1).shape.a = Vector2(0, -16)
	detection_area.get_child(1).shape.b = Vector2(0, 16)

	right = 0
	down = 0
	left = 0
	up = 0

	hide()
	$AnimationPlayer.stop()
	detection_area.monitoring = false
	detection_area.get_child(0).set_deferred("disabled", 1)
	detection_area.get_child(1).set_deferred("disabled", 1)

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

func _ready():
	hide()
	detection_area.monitoring = false
	detection_area.monitorable = false
	detection_area.get_child(0).set_deferred("disabled", 1)
	detection_area.get_child(1).set_deferred("disabled", 1)

@rpc("call_local")
@warning_ignore("SHADOWED_VARIABLE")
func init_detonate(right: int, down: int = right, left: int = right, up: int = right):
	self.right = right
	self.down = down
	self.left = left
	self.up = up

	next_detonate()
	var tile_size: float = tilemap.tile_set.tile_size.x
	detection_area.get_child(0).shape.a = Vector2(-left * tile_size, 0)
	detection_area.get_child(0).shape.b = Vector2(right * tile_size, 0)
	detection_area.get_child(1).shape.a = Vector2(0, - up * tile_size)
	detection_area.get_child(1).shape.b = Vector2(0, down * tile_size)

#Gets called once by init_detonate and then from an animation with increasing steps
func next_detonate(step: int = 0):
	tilemap.set_cell(Vector2i.ZERO, 0, Vector2i(step, 0), 0)
	for x in range(-left, right + 1):
		set_cell_hori(Vector2i(x, 0), -left, right, step)
	for y in range(-up, down + 1):
		set_cell_vert(Vector2i(0, y), -up, down, step)


@rpc("call_local")
func do_detonate():
	show()
	$AnimationPlayer.play("boom") #this animation is freaky ngl
	detection_area.monitoring = true
	detection_area.get_child(0).set_deferred("disabled", 0)
	detection_area.get_child(1).set_deferred("disabled", 0)
	await $AnimationPlayer.animation_finished
	get_parent().done()

func report_kill(killed_player: Player):
	var killer: Player = get_parent().bomb_root.bomb_owner
	killer.misobon_player.revive.rpc(killed_player.synced_position)
	

func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		body.exploded.rpc(str(get_parent().bomb_root.bomb_owner.name).to_int())	
	#print(get_parent().bomb_root.bomb_owner_is_dead)
	if body is Player && get_parent().bomb_root.bomb_owner_is_dead && body.lives - 1 <= 0 && !body.stunned && !body.invulnerable: #TODO This is stupit
		report_kill(body)

func _on_area_2d_entered(area: Area2D) -> void:
	if is_multiplayer_authority() && area.has_method("exploded"):
		area.exploded.rpc(str(get_parent().get_parent().bomb_owner.name).to_int())
