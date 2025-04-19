extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

const CPU_COUNT_DICTIONARY : Dictionary = {
	"Fill" : "Fill",
	"0" : "0",
	"1" : "1",
	"2" : "2",
	"3" : "3",
	"4" : "4"
} 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_cpu_count_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_resolution_index())
	dropdown.select(SettingsContainer.get_resolution_index())
	
func add_cpu_count_items() -> void:
	for cpu_count_option in CPU_COUNT_DICTIONARY:
		dropdown.add_item(cpu_count_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_resolution_selected(index)
