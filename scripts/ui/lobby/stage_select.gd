extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_stage_options()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_cpu_count())
	dropdown.select(SettingsContainer.get_cpu_count())
	
func add_stage_options() -> void:
	for stage_option in SettingsContainer.multiplayer_stages:
		dropdown.add_item(stage_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_stage_set(index)
