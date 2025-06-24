extends Button

@onready var character_rect: TextureRect = %CharacterRect
@onready var save_name_label: Label = %SaveName
@onready var player_name_label: Label = %PlayerName
@onready var score_label: Label = %ScoreLabel
@onready var completion_label: Label = %CompletionLabel
@onready var anim: AnimationPlayer = $AnimationPlayer

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
		Wwise.post_event("snd_click", self)
	else: anim.play("RESET")

func set_save_name(nr: int):
	save_name_label.text = "SAVE " + str(nr)

func set_player_name(player_name: String):
	player_name_label.text = player_name

func set_score_label(score: int):
	var format_string = "%06d"
	score_label.set_text(format_string % [score])

func set_completion_label(val: float):
	completion_label.text = str(int(val * 100)) + "%"

func set_character(character_paths: Dictionary):
	assert(character_paths.has("select"))
	character_rect.texture = load(character_paths.select)

func reset_to_empty():
	player_name_label.text = "Empty"
	var format_string = "%06d"
	score_label.set_text(format_string % [0])
	completion_label.text = "0%"
	character_rect.texture = empty_save_texture.duplicate()
