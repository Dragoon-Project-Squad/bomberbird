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
var mint_flag := "not_boo" #Controls access to secret character Mint.
var snuffy_flag := "not_shiny" #Controls access to secret character Snuffy.
var laimu_flag := "not_ferret" #Controls access to secret character Laimu.
var dooby_flag := "not_doobinit" #Controls access to secret character Dooby.
var nimi_flag := "otsubakuwa" #Controls access to secret character Nimi.

#Multiplayer Enums
enum cpu_difficulty_setting_states {STATIONARY, EASY, MEDIUM, HARD}
enum misobon_setting_states {OFF, ON, SUPER}
enum breakable_spawn_rule_setting_states {STAGE, CUSTOM}
enum pickup_spawn_rule_setting_states {STAGE, CUSTOM}
enum multiplayer_stages {SALOON=0, BEACH=1, DUNGEON=2, LAB=3, SCHOOL=4}
enum multiplayer_stages_secret_enabled {SALOON=0, BEACH=1, DUNGEON=2, LAB=3, SCHOOL=4, SECRET=5}
# Multiplayer
var points_to_win := 3
var cpu_difficulty := cpu_difficulty_setting_states.MEDIUM #The dropdown is set to a dictionary.
var match_time := 120
var hurry_up_time := 60
var hurry_up_state := true
var sudden_death_state := false
var misobon_setting := misobon_setting_states.ON #The dropdown is set to a dictionary.
var breakable_spawn_rule := breakable_spawn_rule_setting_states.STAGE #The dropdown is set to a dictionary.
var breakable_chance := 50.0
var pickup_spawn_rule := pickup_spawn_rule_setting_states.STAGE #The dropdown is set to a dictionary.
var pickup_chance := 100.0
var stage_choice := multiplayer_stages.SALOON

# Held Data Dictionaries
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
		"points_to_win" : points_to_win,
		"cpu_difficulty" : cpu_difficulty,
		"match_time" : match_time,
		"hurry_up_time" : hurry_up_time,
		"hurry_up_state" : hurry_up_state,
		"sudden_death_state" : sudden_death_state,
		"misobon_setting" : misobon_setting,
		"breakable_spawn_rule" : breakable_spawn_rule,
		"breakable_chance" : breakable_chance,
		"pickup_spawn_rule" : pickup_spawn_rule,
		"pickup_chance" : pickup_chance,
		"stage_choice" : stage_choice
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
		print_debug("No loaded data for keybind " + action + "!")
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
	
func get_points_to_win() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_POINTS_TO_WIN
	return points_to_win
	
func get_cpu_difficulty() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_CPU_DIFFICULTY
	return cpu_difficulty

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
		return BATTLE_SETTINGS.DEFAULT_BREAKABLE_SPAWN_RULE
	return breakable_spawn_rule

func get_breakable_chance() -> float:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_BREAKABLE_CHANCE
	return breakable_chance
	
func get_pickup_spawn_rule() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_PICKUP_SPAWN_RULE
	return pickup_spawn_rule

func get_pickup_chance() -> float:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_PICKUP_CHANCE
	return pickup_chance
	
func get_stage_choice() -> int:
	if loaded_data == {}:
		return BATTLE_SETTINGS.DEFAULT_STAGE
	return stage_choice	
	
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

func set_points_to_win(value : int) -> void:
	points_to_win = value

func set_cpu_difficulty(index : int) -> void:
	cpu_difficulty = index as cpu_difficulty_setting_states
	
func set_misobon_setting(index : int) -> void:
	misobon_setting = index as misobon_setting_states

func set_match_time(seconds : int) -> void:
	match_time = seconds
	
func set_hurry_up_time(seconds : int) -> void:
	hurry_up_time = seconds
	
func set_hurry_up_state(isOn : bool) -> void:
	hurry_up_state = isOn
	
func set_sudden_death_state(isOn : bool) -> void:
	sudden_death_state = isOn

func set_breakable_spawn_rule(index : int) -> void:
	breakable_spawn_rule = index as breakable_spawn_rule_setting_states

func set_breakable_chance(value : float) -> void:
	breakable_chance = value
	
func set_pickup_spawn_rule(index : int) -> void:
	pickup_spawn_rule = index as pickup_spawn_rule_setting_states

func set_pickup_chance(value : float) -> void:
	pickup_chance = value
	
func set_stage_choice(index : int) -> void:
	stage_choice = index as multiplayer_stages

func set_options_settings_vars_from_dict(datadict : Dictionary) -> void:
	set_window_mode(datadict.window_mode_index if datadict.has('window_mode_index') else DEFAULT_SETTINGS.DEFAULT_WINDOW_MODE_INDEX)
	set_resolution(datadict.resolution_index if datadict.has('resolution_index') else DEFAULT_SETTINGS.DEFAULT_RESOLUTION_INDEX)
	set_master_vol(datadict.master_volume if datadict.has('master_volume') else DEFAULT_SETTINGS.DEFAULT_MASTER_VOLUME)
	set_music_vol(datadict.music_volume if datadict.has('music_volume') else DEFAULT_SETTINGS.DEFAULT_MUSIC_VOLUME)
	set_sfx_vol(datadict.sfx_volume if datadict.has('sfx_volume') else DEFAULT_SETTINGS.DEFAULT_SFX_VOLUME)
	set_keybinds_loaded(datadict.keybinds if datadict.has('keybinds') else create_keybinds_dictionary())

@rpc("call_local")
func set_battle_settings_vars_from_dict(datadict : Dictionary) -> void:
	set_points_to_win(datadict.points_to_win if datadict.has('points_to_win') else BATTLE_SETTINGS.DEFAULT_POINTS_TO_WIN)
	set_cpu_difficulty(datadict.cpu_difficulty if datadict.has('cpu_difficulty') else BATTLE_SETTINGS.DEFAULT_CPU_DIFFICULTY)
	set_misobon_setting(datadict.misobon_setting if datadict.has('misobon_setting') else BATTLE_SETTINGS.DEFAULT_MISOBON_SETTING)
	set_match_time(datadict.match_time if datadict.has('match_time') else BATTLE_SETTINGS.DEFAULT_MATCH_TIME)
	set_hurry_up_time(datadict.hurry_up_time if datadict.has('hurry_up_time') else BATTLE_SETTINGS.DEFAULT_HURRY_UP_TIME)
	set_hurry_up_state(datadict.hurry_up_state if datadict.has('hurry_up_state') else BATTLE_SETTINGS.DEFAULT_HURRY_UP_STATE)
	set_sudden_death_state(datadict.sudden_death_state if datadict.has('sudden_death_state') else BATTLE_SETTINGS.DEFAULT_SUDDEN_DEATH_STATE)
	set_breakable_spawn_rule(datadict.breakable_spawn_rule if datadict.has('breakable_spawn_rule') else BATTLE_SETTINGS.DEFAULT_BREAKABLE_SPAWN_RULE)
	set_breakable_chance(datadict.breakable_chance if datadict.has('breakable_chance') else BATTLE_SETTINGS.DEFAULT_BREAKABLE_CHANCE)
	set_pickup_spawn_rule(datadict.pickup_spawn_rule if datadict.has('pickup_spawn_rule') else BATTLE_SETTINGS.DEFAULT_PICKUP_SPAWN_RULE)
	set_pickup_chance(datadict.pickup_chance if datadict.has('pickup_chance') else BATTLE_SETTINGS.DEFAULT_PICKUP_CHANCE)
	set_stage_choice(datadict.stage_choice if datadict.has('stage_choice') else BATTLE_SETTINGS.DEFAULT_STAGE)

@rpc("call_local")
func set_stage_choice_from_dict(datadict : Dictionary) -> void:
	set_stage_choice(datadict.stage_choice if datadict.has('stage_choice') else BATTLE_SETTINGS.DEFAULT_STAGE)

func set_all_vars_from_dict(datadict : Dictionary) -> void:
	set_options_settings_vars_from_dict(datadict)
	set_battle_settings_vars_from_dict(datadict)
	
func on_settings_data_loaded(data : Dictionary) -> void:
	#Set Actual Data
	loaded_data = data
	set_all_vars_from_dict(loaded_data)
	
func get_mint_flag() -> String:
	if loaded_data == {}:
		return ""
	return mint_flag
	
func get_snuffy_flag() -> String:
	if loaded_data == {}:
		return ""
	return snuffy_flag
	
func get_laimu_flag() -> String:
	if loaded_data == {}:
		return ""
	return laimu_flag
	
func get_dooby_flag() -> String:
	if loaded_data == {}:
		return ""
	return dooby_flag
	
func get_nimi_flag() -> String:
	if loaded_data == {}:
		return ""
	return nimi_flag
	
func set_mint_flag(secretcode : String) -> void: #Sets Mint flag to unlocked magic number.
	if secretcode.to_lower() != "boo": return
	mint_flag = "boo"
	
func set_snuffy_flag(secretcode : String) -> void: #Sets Snuffy flag to unlocked magic number.
	if secretcode.to_lower() != "shiny": return
	snuffy_flag = "shiny"

func set_laimu_flag(secretcode : String) -> void: #Sets Laimu flag to unlocked magic number.
	if secretcode.to_lower() != "ferret": return
	laimu_flag = "ferret"

func set_dooby_flag(secretcode : String) -> void: #Sets Dooby flag to unlocked magic number.
	if secretcode.to_lower() != "doobinit": return
	dooby_flag = "doobinit"

func set_nimi_flag(secretcode : String) -> void: #Sets Nimi flag to unlocked magic number.
	if secretcode.to_lower() != "konbakuwa": return
	nimi_flag = "konbakuwa"

func clean_all_unlock_flags() -> void:
	clean_mint_flag()
	clean_snuffy_flag()
	clean_laimu_flag()
	clean_dooby_flag()
	clean_nimi_flag()

func clean_mint_flag() -> void:
	mint_flag = "not_boo"
	
func clean_snuffy_flag() -> void:
	snuffy_flag = "not_shiny"
	
func clean_laimu_flag() -> void:
	laimu_flag = "not_ferret"
	
func clean_dooby_flag() -> void:
	dooby_flag = "not_doobinit"
	
func clean_nimi_flag() -> void:
	nimi_flag = "otsubakuwa"

func create_secret_file() -> Dictionary: #Saves save data as permanent secret unlock.
	var secret_file : Dictionary = {
		"mint_flag" = mint_flag,
		"snuffy_flag" = snuffy_flag,
		"laimu_flag" = laimu_flag,
		"dooby_flag" = dooby_flag,
		"nimi_flag" = nimi_flag
	}
	return secret_file
	
func unlock_secret_permanently(secret_to_unlock: String):
	match secret_to_unlock: #First set the flag to the correct one.
		"mint":
			set_mint_flag("boo")
		"snuffy":
			set_snuffy_flag("shiny")
		"laimu":
			set_laimu_flag("ferret")
		"dooby":
			set_dooby_flag("doobinit")
		"nimi":
			set_nimi_flag("konbakuwa")
		_:
			return
	var secret_dict: Dictionary = create_secret_file() #Next, save that to a file.
	SettingsSignalBus.emit_secret_file_data(secret_dict)
	
func on_secret_data_loaded(secretdata : Dictionary) -> void:
	set_mint_flag(secretdata.mint_flag if secretdata.has('mint_flag') else "invalidcode")
	set_snuffy_flag(secretdata.snuffy_flag if secretdata.has('snuffy_flag') else "invalidcode")
	set_laimu_flag(secretdata.laimu_flag if secretdata.has('laimu_flag') else "invalidcode")
	set_dooby_flag(secretdata.dooby_flag if secretdata.has('dooby_flag') else "invalidcode")
	set_nimi_flag(secretdata.nimi_flag if secretdata.has('nimi_flag') else "invalidcode")
	
func handle_signals() -> void:
	SettingsSignalBus.on_window_mode_selected.connect(set_window_mode)
	SettingsSignalBus.on_resolution_selected.connect(set_resolution)
	SettingsSignalBus.on_master_sound_set.connect(set_master_vol)
	SettingsSignalBus.on_music_sound_set.connect(set_music_vol)
	SettingsSignalBus.on_sfx_sound_set.connect(set_sfx_vol)
	SettingsSignalBus.load_settings_data.connect(on_settings_data_loaded)
	SettingsSignalBus.load_secret_data.connect(on_secret_data_loaded)
	SettingsSignalBus.on_points_to_win_set.connect(set_points_to_win)
	SettingsSignalBus.on_cpu_difficulty_set.connect(set_cpu_difficulty)
	SettingsSignalBus.on_match_time_set.connect(set_match_time)
	SettingsSignalBus.on_hurry_up_time_set.connect(set_hurry_up_time)
	SettingsSignalBus.on_hurry_up_state_set.connect(set_hurry_up_state)
	SettingsSignalBus.on_sudden_death_state_set.connect(set_sudden_death_state)
	SettingsSignalBus.on_misobon_mode_set.connect(set_misobon_setting)
	SettingsSignalBus.on_breakable_spawn_rule_set.connect(set_breakable_spawn_rule)
	SettingsSignalBus.on_breakable_chance_set.connect(set_breakable_chance)
	SettingsSignalBus.on_pickup_spawn_rule_set.connect(set_pickup_spawn_rule)
	SettingsSignalBus.on_pickup_chance_set.connect(set_pickup_chance)
	SettingsSignalBus.on_stage_choice_set.connect(set_stage_choice)
