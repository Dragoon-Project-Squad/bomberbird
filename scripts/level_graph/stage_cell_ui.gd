class_name StageCellUI extends ReferenceRect

@export var tileset_texture: Texture2D #"res://assets/tilesetimages/deserttileset.png"
@export var pickup_texture: Texture2D #"res://assets/pickups/powerup.png"
@export var unimplementet_texture: Texture2D #"res://assets/css/question.png"
@export var spawnpoint_texture: Texture2D #"res://assets/css/chonkgoon.png"
@export var random_pickup_texture: Texture2D #"res://assets/pickups/generic_powerup.png"

##One hell of a Dictionary containing the information the create a texture for the given type
@onready var texture_dict: Dictionary = {
	{ "main_type": StageDataUI.tile_type.UNBREAKABLE, "sub_type": null }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(192, 0, 32, 32), "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.SPAWNPOINT, "sub_type": null }:
		{"main_texture": spawnpoint_texture, "main_texture_area": null, "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.ENEMY, "sub_type": "" }:
		{"main_texture": unimplementet_texture, "main_texture_area": null, "sub_texture": null, "sub_texture_area": null},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.RANDOM }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": random_pickup_texture, "sub_texture_area": Rect2i(-1, -2, 24, 24)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.NONE }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": null, "sub_texture_area": null}, #TODO make this a special subtexture
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.BOMB_UP }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(48, 24, 24, 24)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.BOMB_PUNCH }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(144, 0, 24, 24)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.FULL_FIRE }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(168, 0, 24, 24)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.FIRE_UP }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(192, 24, 24, 24)},
	{ "main_type": StageDataUI.tile_type.BREAKABLE, "sub_type": globals.pickups.SPEED_UP }:
		{"main_texture": tileset_texture, "main_texture_area": Rect2i(160, 0, 32, 32), "sub_texture": pickup_texture, "sub_texture_area": Rect2i(216, 24, 24, 24)},
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

## applies the texture specified by 'texture_dict' to this cell
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

## takes a texture and a rect and constructs an AtlasTexture
static func arr_2_atlas(texture: Texture2D, rect: Variant) -> AtlasTexture:
	var atlas_tex: AtlasTexture = AtlasTexture.new()
	atlas_tex.atlas = texture
	if rect != null:
		atlas_tex.region = rect
	return atlas_tex
