extends Area2D

const SPEED = 100

@export var synced_position = Vector2()

@export var throw_gravity: float
var throw_gravity_direction: Vector2

var tile_map: TileMapLayer
var is_thrown: bool = false

func _ready() -> void:
	tile_map = get_node("/root/World/Floor")
	assert(tile_map == null)

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null || is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position;
	
	else:
		#The client updates their progess to the last know one
		position = synced_position

#throw calculates and starts a throw operations
func throw(origin: Vector2, target: Vector2, direction: Vector2i, angle: float):
	assert(direction == Vector2i.LEFT || direction == Vector2i.RIGHT || direction == Vector2i.UP || direction == Vector2i.DOWN)
	var corrected_origin = tile_map.map_to_local(tile_map.local_to_map(origin))
	var corrected_target = tile_map.map_to_local(tile_map.local_to_map(target))

	gravity_direction.x = -direction.y
	gravity_direction.y = direction.x #90 deg clockwise rotation

	
