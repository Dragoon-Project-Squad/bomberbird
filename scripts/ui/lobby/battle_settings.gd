extends Control

@onready var confirm_button: SeButton = $MarginContainer/VBoxContainer/ConfirmButton
@onready var battle_settings_container: Control = $MarginContainer/VBoxContainer/BattleSettingsContainer

func _ready():
	if multiplayer.is_server():
		SettingsSignalBus.on_any_set.connect(update_battle_sets)
	else:
		confirm_button.disabled = true
		confirm_button.text = "Waiting for host"
		update_battle_sets.rpc(SettingsContainer.create_storage_dictionary())
		var options = battle_settings_container.find_child("VBoxContainer", true).get_children()
		for opt in options:
			if opt is BattleSettingControl:
				opt.disable()

func _on_confirm_button_pressed() -> void:
	var options = battle_settings_container.get_children()
	apply_battle_settings.rpc()
	hide()
	gamestate.begin_game()

@rpc("call_local")
func apply_battle_settings() -> void:
	SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_storage_dictionary())

@rpc("call_remote")
func update_battle_sets(settings_dict: Dictionary = {}):
	if multiplayer.is_server():
		update_battle_sets.rpc(SettingsContainer.create_storage_dictionary())
	else:
		if settings_dict.is_empty():
			return
		SettingsContainer.set_battle_settings_vars_from_dict(settings_dict)
		var options = battle_settings_container.find_child("VBoxContainer", true).get_children()
		for opt in options:
			if opt is BattleSettingControl:
				(opt as BattleSettingControl).load_data()
