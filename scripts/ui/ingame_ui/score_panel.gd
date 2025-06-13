class_name ScorePanel extends IconPanel

@onready var score_label: Label = %ScoreLabel
var score = 0

func increment_score():
	score = score + 1
	var format_string = "%01d"
	score_label.set_text(format_string % [score])
	
func decrement_score():
	score = score - 1
	var format_string = "%01d"
	score_label.set_text(format_string % [score])

func set_score(newscore: int):
	score = newscore
	var format_string = "%01d"
	score_label.set_text(format_string % [score])
	
func update_icon(characterpaths: Dictionary):
	match characterpaths["walk"]:
		gamestate.character_texture_paths.EGGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(68, 0, 17, 17)
			print("chara is eggoon")
		gamestate.character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(51, 0, 17, 17)
			print("chara is normalgoon")
		gamestate.character_texture_paths.CHONKGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(17, 0, 17, 17)
			print("chara is chonkgoon")
		gamestate.character_texture_paths.LONGGOON_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(34, 0, 17, 17)
			print("chara is longgoon")
		gamestate.character_texture_paths.BHDOKI_PLAYER_TEXTURE_PATH:
			icon.texture.region = Rect2(0, 0, 17, 17)
			print("chara is bhdoki")
		_:
			icon.texture.region = Rect2(0, 0, 17, 17)
			print("chara is AAAAAAAA")
