class_name StageHandler extends Node2D

var current_stage_path: String 
var loaded_stage_path_map: Dictionary

func get_stage() -> World:
	return loaded_stage_path_map[current_stage_path]

func load_stages(curr_stage_path: String, init_stage_set: Dictionary):
	if !is_multiplayer_authority(): return
	
	for stage_path in init_stage_set.keys():
		if loaded_stage_path_map.has(stage_path): 
			loaded_stage_path_map[stage_path].hide()
			continue
		var stage: World = load(stage_path).instantiate()
		stage.hide()
		add_child(stage)
		loaded_stage_path_map[stage_path] = stage
	
	current_stage_path = curr_stage_path
	get_stage().show()

func free_stages(free_stage_list: Array[World]):
	if !is_multiplayer_authority(): return
	
	for stage_path in free_stage_list:
		if !loaded_stage_path_map.has(stage_path): 
			push_error("Attempted to free a stage not loaded: ", stage_path)
			continue
		loaded_stage_path_map[stage_path].queue_free()
		loaded_stage_path_map.erase(stage_path)
