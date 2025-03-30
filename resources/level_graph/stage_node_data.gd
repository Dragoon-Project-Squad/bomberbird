class_name StageNodeData extends Resource

@export var curr_enemy_options: Array[String]
@export var selected_scene_file: String
@export var selected_scene_path: String

@export var pickup_resource: PickupTable
@export var enemy_resource: EnemyTable
@export var exit_resource: ExitTable
@export var spawn_point_arr: Array[Vector2i]

@export var stage_node_name: String
@export var stage_node_title: String
@export var stage_node_pos: Vector2

@export var index: int
@export var children: Array[int]

func _init():
	self.resource_local_to_scene = true

func get_stage_path() -> String:
	return selected_scene_path + "/" + selected_scene_file
