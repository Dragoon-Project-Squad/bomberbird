extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_misobon_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_misobon_setting())
	dropdown.select(SettingsContainer.get_misobon_setting())
	
func add_misobon_items() -> void:
	for misobon_option in SettingsContainer.misobon_setting_states:
		dropdown.add_item(misobon_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_misobon_mode_set(index)
