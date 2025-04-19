extends Resource
class_name BattleSettingsResource

# CPU
const DEFAULT_CPU_DIFFICULTY := "Medium"
const DEFAULT_CPU_COUNT := "Fill"
# TIME
const DEFAULT_MATCH_TIME := 120
const DEFAULT_HURRY_UP_TIME := 60
const DEFAULT_HURRY_UP_STATE := true
const DEFAULT_SUDDEN_DEATH_STATE := false
const DEFAULT_MISOBON_SETTING := "ON"
# BREAKABLE
const DEFAULT_BREAKABLE_SPAWN_RULE := "Stage"
const DEFAULT_BREAKABLE_CHANCE := 100.0
# PICKUP
const DEFAULT_PICKUP_SPAWN_RULE := "Stage"
const DEFAULT_PICKUP_CHANCE := 100.0

#CPU Settings
@export_enum ("Stationary", "Easy", "Medium", "Hard") var cpu_dfficulty := "Medium"
@export_enum ("Fill", "0", "1", "2", "3", "4") var cpu_count := "Fill"

# Time Settings
var match_time_in_seconds := 120
var hurry_up_time_in_seconds := 60
var is_hurry_up_enabled := true # If Hurry Up mode even activates at all.
var is_sudden_death_enabled := false # Sudden Death Mode makes the Hurry Up blocks keep going to the end.
@export_enum ("OFF", "ON", "SUPER") var MISOBON_SETTING := "ON"
# Breakable Settings
# PRESET - Use the default settings for this map.
# NONE - Spawn no breakables.
# ALL - Fill almost all spaces with breakables.
# CUSTOM - Breakables will appear randomly according to player taste.
@export_group("Breakable Settings")
@export_enum ("Stage", "None", "All", "Custom") var BREAKABLE_SPAWN_RULE := "Stage"
@export var breakable_chance := 100.0
#Use the BreakablePreset resource to manage Breakable Presets.

@export_group("Pickup Settings")
@export_enum ("Stage", "None", "All", "Custom") var PICKUP_SPAWN_RULE := "Stage"
@export var pickup_chance := 100.0
#Use the PickupPreset resource to manage Pickup Presets.
