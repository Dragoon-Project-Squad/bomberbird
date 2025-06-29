class_name IconPanel extends Control

@onready var icon_color_text: TextureRect= %ColoredTexture
@onready var icon: TextureRect = %Icon

var player_id: int

func _ready() -> void:
	icon.texture = AtlasTexture.new()

func update_icon(characterpaths: Dictionary):
	icon.texture.atlas = load(characterpaths.face.path) #just in case there are ever more then one FACE_UI_TEXTURE
	icon.texture.region = str_to_var(characterpaths.face.rect)

func update_icon_color(color: Color):
	icon_color_text.modulate = color
