class_name StageHandler extends Node2D
@onready var stage_spawner: MultiplayerSpawner = $StageSpawner

var current_stage_path: String 
var loaded_stage_path_map: Dictionary

func _ready() -> void:
	globals.game.stage_handler = self

func get_stage() -> World:
	return loaded_stage_path_map[current_stage_path]

func set_stage(next_stage_path) -> void:
	current_stage_path = next_stage_path

func load_stages(next_stage_set: Dictionary):
	if !is_multiplayer_authority(): return
	
	for stage_path in next_stage_set.keys():
		if loaded_stage_path_map.has(stage_path): continue
		var stage: World = stage_spawner.spawn(stage_path)
		loaded_stage_path_map[stage_path] = stage

func free_stages(free_stage_set: Dictionary):
	if !is_multiplayer_authority(): return
	
	for stage_path in free_stage_set.keys():
		if !loaded_stage_path_map.has(stage_path): 
			push_error("Attempted to free a stage that is not loaded: ", stage_path)
			continue
		loaded_stage_path_map[stage_path].free.call_deferred()
		loaded_stage_path_map.erase(stage_path)
