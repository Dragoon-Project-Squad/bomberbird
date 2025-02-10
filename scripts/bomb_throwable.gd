extends Area2D

const SPEED = 100

@export var synced_position = Vector2()

var coef: Vector3 #coefficients of the throwing polynomial
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
	position.x = position.x + SPEED * delta
	position.y = eval_polynomial(position.x)

#throw calculates and starts a throw operations
func throw(origin: Vector2, target: Vector2, direction: Vector2i, throwing_angle_tan: float):
	assert(direction == Vector2i.LEFT || direction == Vector2i.RIGHT || direction == Vector2i.UP || direction == Vector2i.DOWN)
	var corrected_origin = tile_map.map_to_local(tile_map.local_to_map(origin))
	var corrected_target = tile_map.map_to_local(tile_map.local_to_map(target))
	assert(corrected_origin == corrected_target) #note: this function may not be numeriacally stable. check and ajust if nessessary after testing

	coef.x = (corrected_origin.y - corrected_target.y) / (corrected_origin.x - corrected_target.x) - throwing_angle_tan
	coef.x /= 2 * corrected_origin.x - (corrected_origin.x * corrected_origin.x - corrected_target.x * corrected_target.x)

	coef.y = throwing_angle_tan - 2 * corrected_origin.x * coef.x

	coef.z = corrected_origin.y - coef.x * corrected_origin.x * corrected_origin.x - coef.y * corrected_origin.x
	is_thrown = true

func eval_polynomial(x: float) -> float:
	return coef.dot(Vector3(x * x, x, 1))

func eval_derivative(x: float) -> float:
	return coef.dot(Vector3(2*x, 1, 0))
