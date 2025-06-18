extends Control

@onready var dropdown: OptionButton = $HBoxContainer/Dropdown 
signal stage_selected
signal stage_select_aborted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_stage_options()
	load_data()

@rpc("call_remote")
func setup_for_peers() -> void:
	dropdown.disabled = true
	
func load_data() -> void:
	_on_dropdown_item_selected(SettingsContainer.get_stage_choice())
	dropdown.select(SettingsContainer.get_stage_choice())
	
func add_stage_options() -> void:
	var stages = SettingsContainer.multiplayer_stages
	if globals.secrets_enabled: stages = SettingsContainer.multiplayer_stages_secret_enabled
	for stage_option in stages:
		dropdown.add_item(stage_option)

@rpc("call_remote")
func switch_to_secret_stages() -> void:
	print("Come one, come all.")
	dropdown.clear()
	for stage_option in SettingsContainer.multiplayer_stages_secret_enabled:
		dropdown.add_item(stage_option)
	load_data()
	
@rpc("call_remote")
func set_remote_player_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_stage_set(index)
	dropdown.select(index)
	
func _on_dropdown_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_stage_set(index)
	if is_multiplayer_authority():
		set_remote_player_dropdown_item_selected.rpc(index)
	
func _on_back_pressed() -> void:
	if is_multiplayer_authority():
		back_to_previous_screen.rpc()

func _on_start_pressed() -> void:
	if is_multiplayer_authority():
		proceed_to_battle.rpc()
	
@rpc("call_local")
func proceed_to_battle():
	stage_selected.emit()

@rpc("call_local")
func back_to_previous_screen():
	stage_select_aborted.emit()
