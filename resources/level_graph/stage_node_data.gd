class_name StageNodeData extends Resource

@export var selected_scene: String

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
	return StageNode.STAGE_SCENE_DIR + StageNode.STAGE_DIR[self.selected_scene]

func from_json(json_data: Dictionary):
	self.stage_node_name = json_data.stage_node_name
	self.stage_node_title = json_data.stage_node_title
	self.stage_node_pos = str_to_var(json_data.stage_node_pos)
	self.selected_scene = json_data.selected_scene
	self.index = json_data.index
	for exit_id in json_data.children:
		self.children.append(int(exit_id))

	self.pickup_resource = PickupTable.new()
	self.pickup_resource.from_json(json_data.pickup_table)
	self.exit_resource = ExitTable.new()
	self.exit_resource.from_json(json_data.exit_table)
	self.enemy_resource = EnemyTable.new()
	self.enemy_resource.from_json(json_data.enemy_table)
	self.spawnpoint_resource =  SpawnpointTable.new()
	self.spawnpoint_resource.from_json(json_data.spawnpoint_table)
	self.unbreakable_resource = UnbreakableTable.new()
	self.unbreakable_resource.from_json(json_data.unbreakable_table)
	self.breakable_resource = BreakableTable.new()
	self.breakable_resource.from_json(json_data.breakable_table)
