extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown 

enum CPU_COUNT {ZERO, ONE, TWO, THREE, FOUR, FILL}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_cpu_count_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_cpu_count())
	dropdown.select(SettingsContainer.get_cpu_count())
	
func add_cpu_count_items() -> void:
	for cpu_count_option in CPU_COUNT:
		dropdown.add_item(cpu_count_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_cpu_count_set(index)
