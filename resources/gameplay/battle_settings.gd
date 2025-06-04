extends Resource
class_name BattleSettingsResource

# GENERAL
const DEFAULT_POINTS_TO_WIN := 3
const DEFAULT_CPU_DIFFICULTY := 2
const DEFAULT_CPU_COUNT := 5
const DEFAULT_MISOBON_SETTING := 1
const DEFAULT_STAGE := 0

# TIME
const DEFAULT_MATCH_TIME := 120
const DEFAULT_HURRY_UP_TIME := 60
const DEFAULT_HURRY_UP_STATE := true
const DEFAULT_SUDDEN_DEATH_STATE := false
# BREAKABLE
const DEFAULT_BREAKABLE_SPAWN_RULE := 0
const DEFAULT_BREAKABLE_CHANCE := 100.0
# PICKUP
const DEFAULT_PICKUP_SPAWN_RULE := 0
const DEFAULT_PICKUP_CHANCE := 100.0

# General Settings
var points_to_win := 1
@export_enum ("Stationary", "Easy", "Medium", "Hard") var cpu_dfficulty := 2
@export_enum ("0", "1", "2", "3", "4", "Fill") var cpu_count := 5
@export_enum ("OFF", "ON", "SUPER") var MISOBON_SETTING := 1

# Time Settings
var match_time_in_seconds := 120
var hurry_up_time_in_seconds := 60
var is_hurry_up_enabled := true # If Hurry Up mode even activates at all.
var is_sudden_death_enabled := false # Sudden Death Mode makes the Hurry Up blocks keep going to the end.

# Breakable Settings
# PRESET - Use the default settings for this map.
# NONE - Spawn no breakables.
# FULL - Fill almost all spaces with breakables.
# CUSTOM - Breakables will appear randomly according to player taste.
@export_group("Breakable Settings")
@export_enum ("Stage", "None", "Full", "Custom") var BREAKABLE_SPAWN_RULE := 0
@export var breakable_chance := 100.0
#Use the BreakablePreset resource to manage Breakable Presets.

@export_group("Pickup Settings")
@export_enum ("Stage", "None", "All", "Custom") var PICKUP_SPAWN_RULE := 0
@export var pickup_chance := 100.0
#Use the PickupPreset resource to manage Pickup Presets.
