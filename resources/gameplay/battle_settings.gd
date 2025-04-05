extends Resource
class_name BattleSettings

#CPU Settings
@export_enum ("Stationary", "Easy", "Medium", "Hard") var cpu_dfficulty := "Medium"
@export_enum ("None", "1", "2", "3", "4", "Fill") var cpu_count := "Fill"

# Time Settings
var match_time_in_seconds := 120
var hurry_up_time_in_seconds := 60
var is_hurry_up_enabled := true # If Hurry Up mode even activates at all.
var is_sudden_death_enabled := true # Sudden Death Mode makes the Hurry Up blocks keep going to the end.
@export_enum ("OFF", "ON", "SUPER") var MISOBON_SETTING := "ON"
# Breakable Settings
# PRESET - Use the default settings for this map.
# NONE - Spawn no breakables.
# ALL - Fill almost all spaces with breakables.
# CUSTOM - Breakables will appear randomly according to player taste.
@export_group("Breakable Settings")
@export_enum ("Preset", "None", "All", "Custom") var BREAKABLE_SPAWN_RULE := "Preset"
@export var breakable_chance := 100.0
#Use the BreakablePreset resource to manage Breakable Presets.

@export_group("Pickup Settings")
@export_enum ("Preset", "None", "All", "Custom") var PICKUP_SPAWN_RULE := "Preset"
@export var pickup_chance := 100.0
#Use the PickupPreset resource to manage Pickup Presets.
