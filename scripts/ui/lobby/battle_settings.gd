extends Control

@onready var confirm_button: SeButton = $MarginContainer/VBoxContainer/HBoxContainer/ConfirmButton
@onready var battle_settings_container: Control = $MarginContainer/VBoxContainer/BattleSettingsContainer

signal battle_settings_confirmed
signal battle_settings_aborted

func setup_for_host() -> void:
	if not SettingsSignalBus.on_any_set.is_connected(update_battle_sets):
		SettingsSignalBus.on_any_set.connect(update_battle_sets)
	update_battle_sets.rpc(SettingsContainer.create_storage_dictionary())
	
@rpc("call_remote") ##Call remote is default, but I like doing it this way for documentation.
func setup_for_peers() -> void:
	print("I am not the multiplayer authority.")
	confirm_button.disabled = true
	confirm_button.text = "Waiting for host"
	var options = battle_settings_container.find_child("VBoxContainer", true).get_children()
	for opt in options:
		if opt is BattleSettingControl:
			opt.disable()

func _on_confirm_button_pressed() -> void:
	if not is_multiplayer_authority(): return
	var options = battle_settings_container.get_children()
	apply_battle_settings.rpc()
	proceed_to_next_screen.rpc()
	
func _on_back_pressed() -> void:
	if is_multiplayer_authority():
		back_to_previous_screen.rpc()
	
@rpc("call_local")
func proceed_to_next_screen():
	battle_settings_confirmed.emit()

@rpc("call_local")
func back_to_previous_screen():
	battle_settings_aborted.emit()

@rpc("call_local")
func apply_battle_settings() -> void:
	SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_storage_dictionary())

@rpc("call_remote")
func update_battle_sets(settings_dict: Dictionary = {}):
	if is_multiplayer_authority():
		return
	else:
		if settings_dict.is_empty():
			return
		SettingsContainer.set_battle_settings_vars_from_dict(settings_dict)
		var options = battle_settings_container.find_child("VBoxContainer", true).get_children()
		for opt in options:
			if opt is BattleSettingControl:
				(opt as BattleSettingControl).load_data()
