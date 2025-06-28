class_name ObstaclePathResource extends Resource

@export_group("Stage Obstacle Sprite Paths")
@export var desert_path := DEFAULT_DESERT_PATH
@export var beach_path := DEFAULT_BEACH_PATH
@export var dungeon_path := DEFAULT_DUNGEON_PATH
@export var lab_path := DEFAULT_LAB_PATH
@export var secret_path := DEFAULT_SECRET_PATH

const DEFAULT_DESERT_PATH := "res://assets/tilesetimages/desert_obstacles.png"
const DEFAULT_BEACH_PATH := "res://assets/tilesetimages/beach_obstacles.png"
const DEFAULT_DUNGEON_PATH := "res://assets/tilesetimages/dungeon_obstacles.png"
const DEFAULT_LAB_PATH := "res://assets/tilesetimages/lab_obstacles.png"
const DEFAULT_SECRET_PATH := "res://assets/tilesetimages/secret_obstacles.png"

const DEFAULT_DICT = {
	"desert" : DEFAULT_DESERT_PATH,
	"beach" : DEFAULT_BEACH_PATH,
	"dungeon" : DEFAULT_DUNGEON_PATH,
	"lab" : DEFAULT_LAB_PATH,
	"secret" : DEFAULT_SECRET_PATH
}
	
var obstacle_path_dict = {
		"desert" : desert_path,
		"beach" : beach_path,
		"dungeon" : dungeon_path,
		"lab" : lab_path,
		"secret" : secret_path
	}

func create_dict() -> Dictionary:
	var new_dict = {
		"desert" : desert_path,
		"beach" : beach_path,
		"dungeon" : dungeon_path,
		"lab" : lab_path,
		"secret" : secret_path
	}
	return new_dict

func update_internal_dict() -> void:
	obstacle_path_dict = create_dict()

func get_value_by_stage_choice() -> String:
	update_internal_dict()
	var path_to_load : String
	return path_to_load

func get_value_by_argument(choice: int):
	update_internal_dict()
	var path_to_load : String
	match choice:
		SettingsContainer.multiplayer_stages_secret_enabled.SALOON:
			path_to_load = obstacle_path_dict.desert
		SettingsContainer.multiplayer_stages_secret_enabled.BEACH:
			path_to_load = obstacle_path_dict.beach
		SettingsContainer.multiplayer_stages_secret_enabled.DUNGEON:
			path_to_load = obstacle_path_dict.dungeon
		SettingsContainer.multiplayer_stages_secret_enabled.LAB:
			path_to_load = obstacle_path_dict.lab
		SettingsContainer.multiplayer_stages_secret_enabled.SECRET:
			path_to_load = obstacle_path_dict.secret
		_:
			path_to_load = obstacle_path_dict.desert
	return path_to_load
