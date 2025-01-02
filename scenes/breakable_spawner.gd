extends MultiplayerSpawner
const BREAKABLE_SCENE_PATH : String = "res://scenes/breakable.tscn"
@onready var breakable_parent = $"../Breakables"

func _init():
	spawn_function = place_breakable
	
func place_breakable(spawncoords: Vector2):
	#breakable_layer.set_cell(Vector2i(x,y), BREAKABLE_TILE_ID, Vector2i(0,0),0)
	var breakable = preload(BREAKABLE_SCENE_PATH).instantiate()
	breakable.position = spawncoords
	print("We did it, reddit: ", spawncoords)
	#breakable_parent.add_child(breakable)
	return breakable
