extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

const BREAKABLE_SPAWN_RULE_DICTIONARY : Dictionary = {
	"Stage" : "Stage",
	"None" : "None",
	"All" : "All",
	"Custom" : "Custom"
} 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_breakable_spawn_rule_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_resolution_index())
	dropdown.select(SettingsContainer.get_resolution_index())
	
func add_breakable_spawn_rule_items() -> void:
	for breakable_spawn_rule_option in BREAKABLE_SPAWN_RULE_DICTIONARY:
		dropdown.add_item(breakable_spawn_rule_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_resolution_selected(index)
