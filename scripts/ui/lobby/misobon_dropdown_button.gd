extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown

const MISOBON_DICTIONARY : Dictionary = {
	"OFF" : "OFF",
	"ON" : "ON",
	"SUPER" : "SUPER"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_misobon_items()
	load_data()

func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_resolution_index())
	dropdown.select(SettingsContainer.get_resolution_index())
	
func add_misobon_items() -> void:
	for misobon_option in MISOBON_DICTIONARY:
		dropdown.add_item(misobon_option)

func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_resolution_selected(index)
