extends MultiplayerSpawner
const BREAKABLE_SCENE_PATH : String = "res://scenes/breakable.tscn"

var obstaclepaths: ObstaclePathResource = preload("res://resources/gameplay/default_obstacle_paths.tres")


func _init():
	spawn_function = spawn_breakable
	
func spawn_breakable(_data):
	var breakable = load(BREAKABLE_SCENE_PATH).instantiate()
	breakable.set_selected_sprite(obstaclepaths.get_value_by_stage_choice())
	breakable.disable()
	return breakable
