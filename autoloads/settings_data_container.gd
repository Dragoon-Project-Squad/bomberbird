extends Node

@onready var DEFAULT_SETTINGS : DefaultSettingsResource = preload("res://resources/settings/default_settings.tres")
@onready var KEYBIND_RESOURCE : PlayerKeybindResource = preload("res://resources/settings/player_keybind_default.tres")
@onready var BATTLE_SETTINGS : BattleSettingsResource = preload("res://resources/gameplay/default_battle_settings.tres")

#Settings
var window_mode_index := 0
var resolution_index := 0
var master_volume := 0.0
var music_volume := 0.0
var sfx_volume := 0.0

#Multiplayer
var cpu_difficulty := 2 #The dropdown is set to a dictionary.
var cpu_count := 6 #The dropdown is set to a dictionary.
var match_time := 120
var hurry_up_time := 60
var hurry_up_state := true
var sudden_death_state := false
var misobon_setting := 1 #The dropdown is set to a dictionary.
var breakable_spawn_rule := 0 #The dropdown is set to a dictionary.
var breakable_chance := 100.0
var pickup_spawn_rule := 0 #The dropdown is set to a dictionary.
var pickup_chance := 100.0

var loaded_data : Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	handle_signals()

func create_storage_dictionary() -> Dictionary:
	var settings_container_dict : Dictionary = {
		"window_mode_index" : window_mode_index,
		"resolution_index" : resolution_index,
		"master_volume" : master_volume,
		"music_volume" : music_volume,
		"sfx_volume" : sfx_volume,
		"keybinds" : create_keybinds_dictionary(),
		"cpu_difficulty" : cpu_difficulty,
		"cpu_count" : cpu_count,
		"match_time" : match_time,
		"hurry_up_time" : hurry_up_time,
		"hurry_up_state" : hurry_up_state,
		"sudden_death_state" : sudden_death_state,
		"misobon_setting" : misobon_setting,
		"breakable_spawn_rule" : breakable_spawn_rule,
		"breakable_chance" : breakable_chance,
		"pickup_spawn_rule" : pickup_spawn_rule,
		"pickup_chance" : pickup_chance
	}
	return settings_container_dict

func create_keybinds_dictionary() -> Dictionary:
	var keybinds_container_dict : Dictionary = {
		KEYBIND_RESOURCE.MOVE_UP: KEYBIND_RESOURCE.move_up_key,
		KEYBIND_RESOURCE.MOVE_LEFT : KEYBIND_RESOURCE.move_left_key,
		KEYBIND_RESOURCE.MOVE_DOWN : KEYBIND_RESOURCE.move_down_key,
		KEYBIND_RESOURCE.MOVE_RIGHT : KEYBIND_RESOURCE.move_right_key,
		KEYBIND_RESOURCE.SET_BOMB: KEYBIND_RESOURCE.set_bomb_key,
		KEYBIND_RESOURCE.DETONATE_RC : KEYBIND_RESOURCE.detonate_rc_key,
		KEYBIND_RESOURCE.PUNCH_ACTION : KEYBIND_RESOURCE.punch_action_key,
		KEYBIND_RESOURCE.SECONDARY_ACTION : KEYBIND_RESOURCE.secondary_action_key,
		KEYBIND_RESOURCE.PAUSE : KEYBIND_RESOURCE.pause_key,
	}
	
	return keybinds_container_dict

func get_window_mode_index() -> int:
	if loaded_data == {}:
		return DEFAULT_SETTINGS.DEFAULT_WINDOW_MODE_INDEX
	return window_mode_index
	
func get_resolution_index() -> int:
	if loaded_data == {}:
		return DEFAULT_SETTINGS.DEFAULT_RESOLUTION_INDEX
	return resolution_index
	
func get_master_volume() -> float:
	if loaded_data == {}:
		return DEFAULT_SETTINGS.DEFAULT_MASTER_VOLUME
	return master_volume
	
func get_music_volume() -> float:
	if loaded_data == {}:
		return DEFAULT_SETTINGS.DEFAULT_MUSIC_VOLUME
	return music_volume
	
func get_sfx_volume() -> float:
	if loaded_data == {}:
		return DEFAULT_SETTINGS.DEFAULT_SFX_VOLUME
	return sfx_volume
	
func get_keybind(action: String):
	if not loaded_data.has("keybinds"): #If there is no keybinds...
		print("No loaded data!")
		return retrieve_default_keybind(action) #Get the original keybinds.
	else:
		return retrieve_custom_keybind(action) #Get the custom keybinds.

func retrieve_custom_keybind(action : String):
	match action:
		KEYBIND_RESOURCE.MOVE_UP:
			return KEYBIND_RESOURCE.move_up_key
		KEYBIND_RESOURCE.MOVE_LEFT:
			return KEYBIND_RESOURCE.move_left_key
		KEYBIND_RESOURCE.MOVE_DOWN:
			return KEYBIND_RESOURCE.move_down_key
		KEYBIND_RESOURCE.MOVE_RIGHT:
			return KEYBIND_RESOURCE.move_right_key
		KEYBIND_RESOURCE.SET_BOMB:
			return KEYBIND_RESOURCE.set_bomb_key
		KEYBIND_RESOURCE.DETONATE_RC:
			return KEYBIND_RESOURCE.detonate_rc_key
		KEYBIND_RESOURCE.PUNCH_ACTION:
			return KEYBIND_RESOURCE.punch_action_key
		KEYBIND_RESOURCE.SECONDARY_ACTION:
			return KEYBIND_RESOURCE.secondary_action_key
		KEYBIND_RESOURCE.PAUSE:
			return KEYBIND_RESOURCE.pause_key
			
func retrieve_default_keybind(action : String):
	match action:
		KEYBIND_RESOURCE.MOVE_UP:
			return KEYBIND_RESOURCE.DEFAULT_MOVE_UP_KEY
		KEYBIND_RESOURCE.MOVE_LEFT:
			return KEYBIND_RESOURCE.DEFAULT_MOVE_LEFT_KEY
		KEYBIND_RESOURCE.MOVE_DOWN:
			return KEYBIND_RESOURCE.DEFAULT_MOVE_DOWN_KEY
		KEYBIND_RESOURCE.MOVE_RIGHT:
			return KEYBIND_RESOURCE.DEFAULT_MOVE_RIGHT_KEY
		KEYBIND_RESOURCE.SET_BOMB:
			return KEYBIND_RESOURCE.DEFAULT_SET_BOMB_KEY
		KEYBIND_RESOURCE.DETONATE_RC:
			return KEYBIND_RESOURCE.DEFAULT_DETONATE_RC_KEY
		KEYBIND_RESOURCE.PUNCH_ACTION:
			return KEYBIND_RESOURCE.DEFAULT_PUNCH_ACTION_KEY
		KEYBIND_RESOURCE.SECONDARY_ACTION:
			return KEYBIND_RESOURCE.DEFAULT_SECONDARY_ACTION_KEY
		KEYBIND_RESOURCE.PAUSE:
			return KEYBIND_RESOURCE.DEFAULT_PAUSE_KEY
	
func get_cpu_difficulty() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_CPU_DIFFICULTY
	return cpu_difficulty
	
func get_cpu_count() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_CPU_COUNT
	return cpu_count

func get_match_time() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_MATCH_TIME
	return match_time
	
func get_hurry_up_time() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_HURRY_UP_TIME
	return hurry_up_time
	
func get_hurry_up_state() -> bool:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_HURRY_UP_STATE
	return hurry_up_state
	
func get_sudden_death_state() -> bool:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_SUDDEN_DEATH_STATE
	return sudden_death_state
	
func get_misobon_setting() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_MISOBON_SETTING
	return misobon_setting

func get_breakable_spawn_rule() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_MISOBON_SETTING
	return breakable_spawn_rule

func get_breakable_chance() -> float:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_BREAKABLE_CHANCE
	return breakable_chance
	
func get_pickup_spawn_rule() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_MISOBON_SETTING
	return pickup_spawn_rule

func get_pickup_chance() -> float:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_PICKUP_CHANCE
	return pickup_chance
	
func set_window_mode(index : int) -> void:
	window_mode_index = index

func set_resolution(index : int) -> void:
	resolution_index = index
	
func set_master_vol(value : float) -> void:
	master_volume = value
	
func set_music_vol(value : float) -> void:
	music_volume = value
	
func set_sfx_vol(value : float) -> void:
	sfx_volume = value

func set_keybind(action : String, event) -> void:
	match action:
		KEYBIND_RESOURCE.MOVE_UP:
			KEYBIND_RESOURCE.move_up_key = event
		KEYBIND_RESOURCE.MOVE_LEFT:
			KEYBIND_RESOURCE.move_left_key = event
		KEYBIND_RESOURCE.MOVE_DOWN:
			KEYBIND_RESOURCE.move_down_key = event
		KEYBIND_RESOURCE.MOVE_RIGHT:
			KEYBIND_RESOURCE.move_right_key = event
		KEYBIND_RESOURCE.SET_BOMB:
			KEYBIND_RESOURCE.set_bomb_key = event
		KEYBIND_RESOURCE.DETONATE_RC:
			KEYBIND_RESOURCE.detonate_rc_key = event
		KEYBIND_RESOURCE.PUNCH_ACTION:
			KEYBIND_RESOURCE.punch_action_key = event
		KEYBIND_RESOURCE.SECONDARY_ACTION:
			KEYBIND_RESOURCE.secondary_action_key = event
		KEYBIND_RESOURCE.PAUSE:
			KEYBIND_RESOURCE.pause_key = event

func set_keybinds_loaded(data : Dictionary) -> void:
	# Instantialize brand new keybind associations.
	var loaded_move_up = InputEventKey.new()
	var loaded_move_left = InputEventKey.new()
	var loaded_move_down = InputEventKey.new()
	var loaded_move_right = InputEventKey.new()
	var loaded_set_bomb = InputEventKey.new()
	var loaded_detonate_rc = InputEventKey.new()
	var loaded_punch_action = InputEventKey.new()
	var loaded_secondary_action = InputEventKey.new()
	var loaded_pause = InputEventKey.new()
	
	#Fill these new variables with the dictionary.
	loaded_move_up.set_physical_keycode(int(data.move_up))
	loaded_move_left.set_physical_keycode(int(data.move_left))
	loaded_move_down.set_physical_keycode(int(data.move_down))
	loaded_move_right.set_physical_keycode(int(data.move_right))
	loaded_set_bomb.set_physical_keycode(int(data.set_bomb))
	loaded_detonate_rc.set_physical_keycode(int(data.detonate_rc))
	loaded_punch_action.set_physical_keycode(int(data.punch_action))
	loaded_secondary_action.set_physical_keycode(int(data.secondary_action))
	loaded_pause.set_physical_keycode(int(data.pause))
	
	#Edit the keybind resource with these new variables's input events.
	KEYBIND_RESOURCE.move_up_key = loaded_move_up
	KEYBIND_RESOURCE.move_left_key = loaded_move_left
	KEYBIND_RESOURCE.move_down_key = loaded_move_down
	KEYBIND_RESOURCE.move_right_key = loaded_move_right
	KEYBIND_RESOURCE.set_bomb_key = loaded_set_bomb
	KEYBIND_RESOURCE.detonate_rc_key = loaded_detonate_rc
	KEYBIND_RESOURCE.punch_action_key = loaded_punch_action
	KEYBIND_RESOURCE.secondary_action_key = loaded_secondary_action
	KEYBIND_RESOURCE.pause_key = loaded_pause

func set_cpu_difficulty(index : int) -> void:
	cpu_difficulty = index
	
func set_cpu_count(index : int) -> void:
	cpu_count = index

func set_match_time(seconds : int) -> void:
	match_time = seconds
	
func set_hurry_up_time(seconds : int) -> void:
	hurry_up_time = seconds
	
func set_hurry_up_state(isOn : bool) -> void:
	hurry_up_state = isOn
	
func set_sudden_death_state(isOn : bool) -> void:
	sudden_death_state = isOn
	
func set_misobon_setting(index : int) -> void:
	misobon_setting = index

func set_breakable_spawn_rule(index : int) -> void:
	breakable_spawn_rule = index

func set_breakable_chance(value : float) -> void:
	breakable_chance = value
	
func set_pickup_spawn_rule(index : int) -> void:
	pickup_spawn_rule = index

func set_pickup_chance(value : float) -> void:
	pickup_chance = value

func on_settings_data_loaded(data : Dictionary) -> void:
	loaded_data = data
	set_window_mode(loaded_data.window_mode_index)
	set_resolution(loaded_data.resolution_index)
	set_master_vol(loaded_data.master_volume)
	set_music_vol(loaded_data.music_volume)
	set_sfx_vol(loaded_data.sfx_volume)
	set_keybinds_loaded(loaded_data.keybinds)
	set_cpu_difficulty(loaded_data.cpu_difficulty)
	set_cpu_count(loaded_data.cpu_count)
	set_match_time(loaded_data.match_time)
	set_hurry_up_time(loaded_data.hurry_up_time)
	set_hurry_up_state(loaded_data.hurry_up_state)
	set_sudden_death_state(loaded_data.sudden_death_state)
	set_misobon_setting(loaded_data.misobon_setting)
	set_breakable_spawn_rule(loaded_data.breakable_spawn_rule)
	set_breakable_chance(loaded_data.breakable_chance)
	set_pickup_spawn_rule(loaded_data.pickup_spawn_rule)
	set_pickup_chance(loaded_data.pickup_chance)
	
func handle_signals() -> void:
	SettingsSignalBus.on_window_mode_selected.connect(set_window_mode)
	SettingsSignalBus.on_resolution_selected.connect(set_resolution)
	SettingsSignalBus.on_master_sound_set.connect(set_master_vol)
	SettingsSignalBus.on_music_sound_set.connect(set_music_vol)
	SettingsSignalBus.on_sfx_sound_set.connect(set_sfx_vol)
	SettingsSignalBus.load_settings_data.connect(on_settings_data_loaded)
	SettingsSignalBus.on_cpu_difficulty_set.connect(set_cpu_difficulty)
	SettingsSignalBus.on_cpu_count_set.connect(set_cpu_count)
	SettingsSignalBus.on_match_time_set.connect(set_match_time)
	SettingsSignalBus.on_hurry_up_time_set.connect(set_hurry_up_time)
	SettingsSignalBus.on_hurry_up_state_set.connect(set_hurry_up_state)
	SettingsSignalBus.on_sudden_death_state_set.connect(set_sudden_death_state)
	SettingsSignalBus.on_misobon_mode_set.connect(set_misobon_setting)
	SettingsSignalBus.on_breakable_spawn_rule_set.connect(set_breakable_spawn_rule)
	SettingsSignalBus.on_breakable_chance_set.connect(set_breakable_chance)
	SettingsSignalBus.on_pickup_spawn_rule_set.connect(set_pickup_spawn_rule)
	SettingsSignalBus.on_pickup_chance_set.connect(set_pickup_chance)
