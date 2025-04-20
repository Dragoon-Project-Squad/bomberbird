extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

enum CPU_DIFFICULTY {STATIONARY, EASY, MEDIUM, HARD}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_cpu_difficulty_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_cpu_difficulty())
	dropdown.select(SettingsContainer.get_cpu_difficulty())
	
func add_cpu_difficulty_items() -> void:
	for cpu_difficulty_option in CPU_DIFFICULTY:
		dropdown.add_item(cpu_difficulty_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_cpu_difficulty_set(index)
