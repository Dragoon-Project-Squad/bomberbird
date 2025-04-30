extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_breakable_spawn_rule_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_breakable_spawn_rule())
	dropdown.select(SettingsContainer.get_breakable_spawn_rule())
	
func add_breakable_spawn_rule_items() -> void:
	for breakable_spawn_rule_option in SettingsContainer.breakable_spawn_rule_setting_states:
		dropdown.add_item(breakable_spawn_rule_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_breakable_spawn_rule_set(index)
