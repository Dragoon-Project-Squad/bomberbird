class_name StageNodeData extends Resource

@export var curr_enemy_options: Array[String]
@export var selected_scene_file: String
@export var selected_scene_path: String

@export var pickup_resource: PickupTable
@export var enemy_resource: EnemyTable
@export var exit_resource: ExitTable
@export var spawnpoint_resource: SpawnpointTable
@export var unbreakable_resource: UnbreakableTable
@export var breakable_resource: BreakableTable

@export var stage_node_name: String
@export var stage_node_title: String
@export var stage_node_pos: Vector2

@export var index: int
@export var children: Array[int]

## make sure this is not a shared resource
func _init():
	self.resource_local_to_scene = true

## returns the full path to the stage this data file corresponts to
func get_stage_path() -> String:
	return selected_scene_path + "/" + selected_scene_file
