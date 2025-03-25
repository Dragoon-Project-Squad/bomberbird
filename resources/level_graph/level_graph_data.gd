class_name LevelGraphData extends Resource

@export var stage_node_indx: int
@export var file_name: String

@export var connections: Array[Dictionary]
@export var nodes: Array[StageNodeData]

@export var entry_point_pos: Vector2

func _init():
	self.resource_local_to_scene = true


