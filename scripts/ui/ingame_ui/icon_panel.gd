class_name IconPanel extends Control

@onready var icon_color_text: TextureRect= %ColoredTexture
@onready var icon: TextureRect = %Icon

func _ready() -> void:
	icon.texture = AtlasTexture.new()

var player_id: int = -1

func update_icon(characterpaths: Dictionary):
	icon.texture.atlas = load(characterpaths.face.path) #just in case there are ever more then one FACE_UI_TEXTURE
	icon.texture.region = characterpaths.face.rect

func update_icon_color(color: Color):
	icon_color_text.modulate = color
