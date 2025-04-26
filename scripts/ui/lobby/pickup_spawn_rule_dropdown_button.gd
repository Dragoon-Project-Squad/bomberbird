extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

enum PICKUP_SPAWN_RULE_OPTIONS {STAGE, NONE, ALL, CUSTOM}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_pickup_spawn_rule_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_pickup_spawn_rule())
	dropdown.select(SettingsContainer.get_pickup_spawn_rule())
	
func add_pickup_spawn_rule_items() -> void:
	for pickup_spawn_rule_option in PICKUP_SPAWN_RULE_OPTIONS:
		dropdown.add_item(pickup_spawn_rule_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_pickup_spawn_rule_set(index)
