extends MultiplayerSpawner
const EXPLOSION_SCENE_PATH : String = "res://scenes/explosion.tscn"

func _init():
	spawn_function = place_explosion
	
func place_explosion(data):
	#breakable_layer.set_cell(Vector2i(x,y), BREAKABLE_TILE_ID, Vector2i(0,0),0)
	var explosion = preload(EXPLOSION_SCENE_PATH).instantiate()
	explosion.position = data.spawnpoint
	explosion.bombowner = data.bombowner
	match data.explosiontype:
		"center":
			explosion.type = explosion.CENTER
		"side_border":
			explosion.type = explosion.SIDE_BORDER
		_:
			explosion.type = explosion.SIDE
	explosion.direction = data.direction
	#breakable_parent.add_child(breakable)
	return explosion
