extends BattleSettingControl

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_pickup_spawn_rule_items()
	load_data()

func load_data() -> void:
	dropdown.select(SettingsContainer.get_pickup_spawn_rule())
	
func add_pickup_spawn_rule_items() -> void:
	for pickup_spawn_rule_option in SettingsContainer.pickup_spawn_rule_setting_states:
		dropdown.add_item(pickup_spawn_rule_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_pickup_spawn_rule_set(index)

func disable() -> void:
	dropdown.disabled = true
