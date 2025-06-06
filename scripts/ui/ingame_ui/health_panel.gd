class_name HealthPanel extends Control

@onready var health_label: Label = %HealthLabel
@onready var icon_color_text: TextureRect= %ColoredTexture
@onready var icon: TextureRect = %Icon

var player_id: int = -1

func update_health(health: int):
	var format_string = "%01d"
	health_label.set_text(format_string % [health])

func update_icon(character: String):
	match character:
		gamestate.character_texture_paths.EGGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(192, 96, 32, 32)
		gamestate.character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(161, 96, 32, 32)
		gamestate.character_texture_paths.CHONKGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(96, 96, 32, 32)
		gamestate.character_texture_paths.LONGGOON_SELECT_TEXTURE_PATH:
			icon.texture.region = Rect2(128, 96, 32, 32)
		gamestate.character_texture_paths.BHDOKI_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(64, 96, 32, 32)
		_:
			icon.texture.region = Rect2(64, 96, 32, 32)

func update_icon_color(color: Color):
	icon_color_text.modulate = color
