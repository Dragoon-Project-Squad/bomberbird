class_name StageHandler extends Node2D
## Class for handeling the spawning and freeing of stages
@onready var stage_spawner: MultiplayerSpawner = $StageSpawner

var current_stage_path: String 
var loaded_stage_path_map: Dictionary

func _ready() -> void:
	globals.game.stage_handler = self

## returns the current stage
func get_stage() -> World:
	return loaded_stage_path_map[current_stage_path]

## sets the current stage
func set_stage(next_stage_name: String) -> void:
	current_stage_path = StageNode.STAGE_SCENE_DIR + StageNode.STAGE_DIR[next_stage_name]

## loads all stages given in the
## [param next_stage_set] Dictionary used as a set containing Path Strings
## Ignoring all stages already loaded
func load_stages(next_stage_set: Dictionary):
	if !is_multiplayer_authority(): return
	
	for stage_path in next_stage_set.keys():
		if loaded_stage_path_map.has(stage_path): continue
		var stage: World = stage_spawner.spawn(stage_path)
		loaded_stage_path_map[stage_path] = stage

## frees all stages given in the
## [param free_stage_set] Dictionary used as a set containing Path Strings
## Throws an error if a non loaded stage is attempted to be freed
func free_stages(free_stage_set: Dictionary):
	if !is_multiplayer_authority(): return
	
	for stage_path in free_stage_set.keys():
		if !loaded_stage_path_map.has(stage_path): 
			push_error("Attempted to free a stage that is not loaded: ", stage_path)
			continue
		loaded_stage_path_map[stage_path].queue_free()
		loaded_stage_path_map.erase(stage_path)
