class_name StageCellUI extends ReferenceRect

static var tileset_texture: String = "res://assets/tilesetimages/deserttileset.png"
static var pickup_texture: String = "res://assets/pickups/powerup.png"
static var unimplementet_texture: String = "res://assets/css/question.png"
static var spawnpoint_texture: String = "res://assets/css/chonkgoon.png"

static var texture_dict: Dictionary = {
	[StageDataUI.tile_type.UNBREAKABLE, null]: [[tileset_texture, Rect2i(192, 0, 32, 32)], null],
	[StageDataUI.tile_type.SPAWNPOINT, null]: [[spawnpoint_texture, null], null],
	[StageDataUI.tile_type.ENEMY, ""]: [[unimplementet_texture, null], null],
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.RANDOME]: [[tileset_texture, Rect2i(160, 0, 32, 32)], null],
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.NONE]: [[tileset_texture, Rect2i(160, 0, 32, 32)], null], #TODO make this a special subtexture
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.BOMB_UP]: [[tileset_texture, Rect2i(160, 0, 32, 32)], [pickup_texture, Rect2i(32, 0, 32, 32)]],
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.BOMB_PUNCH]: [[tileset_texture, Rect2i(160, 0, 32, 32)], [pickup_texture, Rect2i(64, 0, 32, 32)]],
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.FULL_FIRE]: [[tileset_texture, Rect2i(160, 0, 32, 32)], [pickup_texture, Rect2i(0, 32, 32, 32)]],
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.FIRE_UP]: [[tileset_texture, Rect2i(160, 0, 32, 32)], [pickup_texture, Rect2i(32, 32, 32, 32)]],
	[StageDataUI.tile_type.BREAKABLE, globals.pickups.SPEED_UP]: [[tileset_texture, Rect2i(160, 0, 32, 32)], [pickup_texture, Rect2i(64, 32, 32, 32)]],
	[StageDataUI.tile_type.BREAKABLE, -1]: [[tileset_texture, Rect2i(160, 0, 32, 32)], [unimplementet_texture, null]],
}

@onready var main_texture: TextureRect = $MainTexture
@onready var sub_texture: TextureRect = $SubTexture
@onready var probability_label: Label = $Probability

## constructor function
static func create(start_texture: Array = []) -> StageCellUI:
	var stage_cell_ui: StageCellUI = load("res://scenes/level_graph/stage_cell_ui.tscn").instantiate()
	if start_texture == []: return stage_cell_ui
	stage_cell_ui.apply_texture(start_texture)
	stage_cell_ui.probability_label.hide()
	return stage_cell_ui

func apply_texture(texture_data: Array = []) -> void:
	main_texture.texture = null
	sub_texture.texture = null
	if texture_data == []:
		probability_label.hide()
		return
	probability_label.show()
	probability_label.text = str(texture_data[-1])
	var texture_data_sliced: Array = texture_data.slice(0, 2)

	if texture_dict.has(texture_data_sliced):
		main_texture.texture = arr_2_atlas(texture_dict[texture_data_sliced][0])
		if len(texture_dict[texture_data_sliced]) > 1 && texture_dict[texture_data_sliced][1] != null:
			sub_texture.texture = arr_2_atlas(texture_dict[texture_data_sliced][1])
	elif texture_dict.has([texture_data_sliced[0], ""]): #unimplemented enemy
		main_texture.texture = arr_2_atlas(texture_dict[[texture_data_sliced[0], ""]][0])
		if len(texture_dict[[texture_data_sliced[0], ""]]) > 1 && texture_dict[[texture_data_sliced[0], ""]][1] != null:
			sub_texture.texture = arr_2_atlas(texture_dict[[texture_data_sliced[0], ""]][1])
	elif texture_dict.has([texture_data_sliced[0], -1]): #unimplemented pickup
		main_texture.texture = arr_2_atlas(texture_dict[[texture_data_sliced[0], -1]][0])
		if len(texture_dict[[texture_data_sliced[0], -1]]) > 1 && texture_dict[[texture_data_sliced[0], -1]][1] != null:
			sub_texture.texture = arr_2_atlas(texture_dict[[texture_data_sliced[0], -1]][1])
	else:
		push_error("Invalid texture data")
	

static func arr_2_atlas(atlas_data: Array) -> AtlasTexture:
	var atlas_tex: AtlasTexture = AtlasTexture.new()
	atlas_tex.atlas = ImageTexture.create_from_image(Image.load_from_file(atlas_data[0]))
	if atlas_data[1] != null:
		atlas_tex.region = atlas_data[1]
	return atlas_tex
