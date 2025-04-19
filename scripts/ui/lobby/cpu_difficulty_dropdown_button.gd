extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

const CPU_DIFFICULTY_DICTIONARY : Dictionary = {
	"Stationary" : "Stationary",
	"Easy" : "Easy",
	"Medium" : "Medium",
	"Hard" : "Hard"
} 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_cpu_difficulty_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_resolution_index())
	dropdown.select(SettingsContainer.get_resolution_index())
	
func add_cpu_difficulty_items() -> void:
	for cpu_difficulty_option in CPU_DIFFICULTY_DICTIONARY:
		dropdown.add_item(cpu_difficulty_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_resolution_selected(index)
