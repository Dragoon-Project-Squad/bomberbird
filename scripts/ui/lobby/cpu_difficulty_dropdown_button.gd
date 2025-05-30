extends BattleSettingControl

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_cpu_difficulty_items()
	super._ready()

func load_data() -> void:
	dropdown.select(SettingsContainer.get_cpu_difficulty())
	
func add_cpu_difficulty_items() -> void:
	for cpu_difficulty_option in SettingsContainer.cpu_difficulty_setting_states:
		dropdown.add_item(cpu_difficulty_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_cpu_difficulty_set(index)

func disable() -> void:
	dropdown.disabled = true
