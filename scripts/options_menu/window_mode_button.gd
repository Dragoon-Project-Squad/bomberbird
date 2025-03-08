extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton

const WINDOW_MODE_ARRAY : Array[String] = [
	"Fullscreen",
	"Windowed",
	"Borderless Window",
	"Borderless Fullscreen"
]

func _ready() -> void:
	add_window_mode_items()

func add_window_mode_items():
	for window_mode in WINDOW_MODE_ARRAY:
		option_button.add_item(window_mode)

func _on_window_mode_selected(index: int) -> void:
	SettingsSignalBus.emit_on_window_mode_selected(index)
	
	match index:
		0: #Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: #Window Mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: #Borderless Window
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		3: #Borderless Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
