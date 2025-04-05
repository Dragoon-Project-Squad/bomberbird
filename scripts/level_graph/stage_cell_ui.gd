class_name StageCellUI extends ReferenceRect

static var tileset_texture: String = "res://assets/tilesetimages/deserttileset.png"
static var pickup_texture: String = "res://assets/pickups/powerup.png"
static var unimplementet_texture: String = "res://assets/css/question.png"
static var spawnpoint_texture: String = "res://assets/css/chonkgoon.png"

##One hell of a Dictionary containing the information the create a texture for the given type
static var texture_dict: Dictionary = {
	{ "main_type": StageDataUI.tile_type.UNBREAKABLE, "sub_type": null }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(192, 0, 32, 32), "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.SPAWNPOINT, "sub_type": null }:
		{"main_texture": spawnpoint_texture, "main_texture_area": null, "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.ENEMY, "sub_type": "" }:
		{"main_texture": unimplementet_texture, "main_texture_area": null, "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.RANDOME }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.NONE }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": null, "sub_texture_area": null}, #TODO make this a special subtexture
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.BOMB_UP }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(32, 0, 32, 32)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.BOMB_PUNCH }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(64, 0, 32, 32)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.FULL_FIRE }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(0, 32, 32, 32)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.FIRE_UP }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(32, 32, 32, 32)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.SPEED_UP }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(64, 32, 32, 32)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": -1 }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": unimplementet_texture, "sub_texture_area": null},
}

@onready var main_texture: TextureRect = $MainTexture
@onready var sub_texture: TextureRect = $SubTexture
@onready var probability_label: Label = $Probability

## constructor function
static func create(start_texture: Dictionary = {}) -> StageCellUI:
	var stage_cell_ui: StageCellUI = load("res://scenes/level_graph/stage_cell_ui.tscn").instantiate()
	if start_texture == {}: return stage_cell_ui
	stage_cell_ui.apply_texture(start_texture)
	stage_cell_ui.probability_label.hide()
	return stage_cell_ui

func apply_texture(texture_data: Dictionary = {}) -> void:
	main_texture.texture = null
	sub_texture.texture = null
	if texture_data == {}:
		probability_label.hide()
		return
	probability_label.show()
	probability_label.text = str(texture_data.probability)
	var texture_data_sliced: Dictionary = texture_data.duplicate() 
	texture_data_sliced.erase("probability")

	for sub_type in [texture_data_sliced.sub_type, "", -1]: #Hacky hack hack
		texture_data_sliced.sub_type = sub_type
		if texture_dict.has(texture_data_sliced):
			main_texture.texture = arr_2_atlas(texture_dict[texture_data_sliced].main_texture, texture_dict[texture_data_sliced].main_texture_area)
			if texture_dict[texture_data_sliced].sub_texture != null:
				sub_texture.texture = arr_2_atlas(texture_dict[texture_data_sliced].sub_texture, texture_dict[texture_data_sliced].sub_texture_area)
			return

static func arr_2_atlas(path: String, rect: Variant) -> AtlasTexture:
	var atlas_tex: AtlasTexture = AtlasTexture.new()
	atlas_tex.atlas = ImageTexture.create_from_image(Image.load_from_file(path))
	if rect != null:
		atlas_tex.region = rect
	return atlas_tex
