extends Node

enum gamemode {
	NONE,
	CAMPAIGN,
	BATTLEMODE
}

enum pickups {
	BOMB_UP = 0,
	FIRE_UP,
	SPEED_UP,
	HP_UP,
	GENERIC_COUNT, # A generic value describing some pickup that can be picked up multiple times
	FULL_FIRE,
	BOMB_PUNCH,
	POWER_GLOVE,
	WALLTHROUGH,
	FREEZE,
	INVINCIBILITY_VEST,
	VIRUS,
	GENERIC_BOOL, # A generic value describing some pickup that can only be held once
	KICK,
	BOMBTHROUGH,
	GENERIC_EXCLUSIVE, # A generic value describing some pickup which must be mutually exclusivly held with any other in this group
	PIERCING,
	MINE,
	REMOTE,
	SEEKER,
	GENERIC_BOMB, # A generic value describing a pickup that changes the bomb type (also mutaly exclusive with other bomb types)
	NONE, # A value describing the absens of a pickup
	RANDOM, # A value describing a random pickup
}

static var pickup_name_str: Dictionary = {
	pickups.BOMB_UP: "extra_bomb",
	pickups.FIRE_UP: "explosion_boost",
	pickups.SPEED_UP: "speed_boost",
	pickups.HP_UP: "hearth",
	pickups.GENERIC_COUNT: "countable_pickups",
	pickups.FULL_FIRE: "max_explosion",
	pickups.BOMB_PUNCH: "punch_ability",
	pickups.POWER_GLOVE: "throw_ability",
	pickups.WALLTHROUGH: "wallthrough",
	pickups.FREEZE: "timer",
	pickups.INVINCIBILITY_VEST: "invincibility_vest",
	pickups.VIRUS: "virus",
	pickups.GENERIC_BOOL: "on/off_pickups",
	pickups.KICK: "kick",
	pickups.BOMBTHROUGH: "bombthrough",
	pickups.GENERIC_EXCLUSIVE: "exclusive_pickups",
	pickups.PIERCING: "piercing_bomb",
	pickups.MINE: "land_mine",
	pickups.REMOTE: "remote_control",
	pickups.SEEKER: "seeker_bomb",
	pickups.GENERIC_BOMB: "bomb_type_pickups",
	pickups.NONE: "no_pickup",
	pickups.RANDOM: "random",
}

const BEACH_FULL_STAGE_PATH = "res://scenes/stages/beach_stages/beach_full.tscn"
const BEACH_RAND_STAGE_PATH = "res://scenes/stages/beach_stages/beach_rand.tscn"
const DESERT_FULL_STAGE_PATH = "res://scenes/stages/desert/desert_full.tscn"
const DESERT_RAND_STAGE_PATH = "res://scenes/stages/desert/desert_rand.tscn"
const DUNGEON_FULL_STAGE_PATH = "res://scenes/stages/dungeon_stages/dungeon_full.tscn"
const DUNGEON_RAND_STAGE_PATH = "res://scenes/stages/dungeon_stages/dungeon_rand.tscn"
const LAB_FULL_STAGE_PATH = "res://scenes/stages/lab_stages/lab_full.tscn"
const LAB_RAND_STAGE_PATH = "res://scenes/stages/lab_stages/lab_rand.tscn"
const MULTIPLAYER_VICTORY_SCREEN_PATH = "res://scenes/victory_screen.tscn"

var current_gamemode := gamemode.NONE
var config = Config.new()
var game: Node2D
var current_world: World
var player_manager: PlayerManager

func is_valid_pickup(pickup: int):
	match pickup:
		pickups.GENERIC_COUNT: return false
		pickups.GENERIC_BOOL: return false
		pickups.GENERIC_BOMB: return false
		pickups.GENERIC_EXCLUSIVE: return false
		pickups.NONE: return false
		pickups.RANDOM: return false
	return true

func is_not_pickup_seperator(pickup: int):
	match pickup:
		pickups.GENERIC_COUNT: return false
		pickups.GENERIC_BOOL: return false
		pickups.GENERIC_BOMB: return false
		pickups.GENERIC_EXCLUSIVE: return false
	return true
