extends Button

@onready var character_rect: TextureRect = %CharacterRect
@onready var save_name_label: Label = %SaveName
@onready var player_name_label: Label = %PlayerName
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var empty_save_texture = character_rect.texture.duplicate()

var is_toggled_on: bool = false

func _on_hover_entered():
	if self.is_toggled_on: return
	anim.play("hover")

func _on_hover_exit():
	if self.is_toggled_on: return
	anim.play("RESET")

func _on_toggled(button: BaseButton) -> void:
	self.is_toggled_on = button == self
	if self.is_toggled_on:
		anim.play("select")
		audio_player.play()
	else: anim.play("RESET")

func set_save_name(nr: int):
	save_name_label.text = "SAVE " + str(nr)

func set_player_name(player_name: String):
	player_name_label.text = player_name

func set_character(character_paths: Dictionary):
	assert(character_paths.has("select"))
	character_rect.texture = load(character_paths.select)

func reset_to_empty():
	player_name_label.text = "Empty"
	character_rect.texture = empty_save_texture.duplicate()

# TODO: have highscore and completion rate displayed
	
