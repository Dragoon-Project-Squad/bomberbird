extends Node

signal on_window_mode_selected(index : int)
signal on_resolution_selected(index: int)
signal on_master_sound_set(value : float)
signal on_music_sound_set(value : float)
signal on_sfx_sound_set(value : float)
signal load_settings_data(settings_dict: Dictionary)
signal set_settings_dictionary(settings_dict : Dictionary)
# Multiplayer
signal on_points_to_win_set(value : int)
signal on_cpu_difficulty_set(value : int)
signal on_cpu_count_set(value : int)
signal on_match_time_set(value : float)
signal on_hurry_up_time_set(value : float)
signal on_hurry_up_state_set(value : bool)
signal on_sudden_death_state_set(value : bool)
signal on_misobon_mode_set(value : int)
signal on_breakable_spawn_rule_set(value : int)
signal on_breakable_chance_set(value : float)
signal on_pickup_spawn_rule_set(value : int)
signal on_pickup_chance_set(value : float)
signal on_any_set

# Options Emit Functions

func emit_load_settings_data(settings_dict: Dictionary) -> void:
	load_settings_data.emit(settings_dict)
	on_any_set.emit()

func emit_on_window_mode_selected(index : int) -> void:
	on_window_mode_selected.emit(index)
	on_any_set.emit()

func emit_on_resolution_selected(index : int) -> void:
	on_resolution_selected.emit(index)
	on_any_set.emit()
	
func emit_on_master_sound_set(value : float) -> void:
	on_master_sound_set.emit(value)
	on_any_set.emit()
	
func emit_on_music_sound_set(value : float) -> void:
	on_music_sound_set.emit(value)
	on_any_set.emit()
	
func emit_on_sfx_sound_set(value : float) -> void:
	on_sfx_sound_set.emit(value)
	on_any_set.emit()
	
func emit_set_settings_dictionary(settings_dict : Dictionary) -> void:
	set_settings_dictionary.emit(settings_dict)

# Multiplayer Emit Functions

func emit_on_cpu_difficulty_set(value : int) -> void:
	on_cpu_difficulty_set.emit(value)
	on_any_set.emit()

func emit_on_points_to_win_set(value : int) -> void:
	on_points_to_win_set.emit(value)
	on_any_set.emit()
	
func emit_on_cpu_count_set(value : int) -> void:
	on_cpu_count_set.emit(value)
	on_any_set.emit()

func emit_on_match_time_set(value : float) -> void:
	on_match_time_set.emit(value)
	on_any_set.emit()

func emit_on_hurry_up_time_set(value : float) -> void:
	on_hurry_up_time_set.emit(value)
	on_any_set.emit()
	
func emit_on_hurry_up_state_set(toggled_on : bool) -> void:
	on_hurry_up_state_set.emit(toggled_on)
	on_any_set.emit()
	
func emit_on_sudden_death_state_set(toggled_on : bool) -> void:
	on_sudden_death_state_set.emit(toggled_on)
	on_any_set.emit()
	
func emit_on_misobon_mode_set(value : int) -> void:
	on_misobon_mode_set.emit(value)
	on_any_set.emit()
	
func emit_on_breakable_spawn_rule_set(value : int) -> void:
	on_breakable_spawn_rule_set.emit(value)
	on_any_set.emit()

func emit_on_breakable_chance_set(value : float) -> void:
	on_breakable_chance_set.emit(value)
	on_any_set.emit()
	
func emit_on_pickup_spawn_rule_set(value : int) -> void:
	on_pickup_spawn_rule_set.emit(value)
	on_any_set.emit()
	
func emit_on_pickup_chance_set(value : float) -> void:
	on_pickup_chance_set.emit(value)
	on_any_set.emit()
