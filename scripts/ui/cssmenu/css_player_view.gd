extends Control
class_name PlayerControl
@export_enum("???","Player 1","Player 2","Player 3","Player 4") var player_number : String = "???"
@onready var player_label: Label = $PlayerPanel/Text
@onready var player_panel: Panel = $PlayerPanel
@onready var player_image: TextureRect = $PlayerPanel/Image
var is_participating := true

func _ready() -> void:
	setup_player()

@rpc("authority", "call_local")
func set_texture(image_path) -> void:
	player_image.texture = load(image_path)

func setup_player() -> void:
	set_player_panel_theme()
	match player_number:
		"Player 1":
			set_player_name_label_text("P1")
		"Player 2":
			set_player_name_label_text("P2")
		"Player 3":
			set_player_name_label_text("P3")
		"Player 4":
			set_player_name_label_text("P4")
		_:
			set_player_name_label_text("???")
			
func set_player_name_label_text(some_text : String) -> void:
	player_label.text = some_text
	
func set_player_panel_theme() -> void:
	match player_number:
		"Player 1":
			player_panel.theme = load("res://assets/styles/p1_theme.tres")
		"Player 2":
			player_panel.theme = load("res://assets/styles/p2_theme.tres")
		"Player 3":
			player_panel.theme = load("res://assets/styles/p3_theme.tres")
		"Player 4":
			player_panel.theme = load("res://assets/styles/p4_theme.tres")
		_:
			player_panel.theme = load("res://assets/styles/p0_theme.tres")

func set_is_participating(participation_flag: bool) -> void:
	is_participating = participation_flag
	player_image.visible = participation_flag
	player_label.visible = participation_flag
	$PlayerPanel/Button.disabled = participation_flag
	$PlayerPanel/ClickPrompt.visible = !participation_flag


func _on_button_pressed():
	if is_multiplayer_authority():
		gamestate.establish_player_counts()
		gamestate.assign_player_numbers()
		gamestate.register_ai_player()
		SettingsContainer.set_cpu_count(SettingsContainer.get_cpu_count()+1)
		gamestate.player_list_changed.emit()
