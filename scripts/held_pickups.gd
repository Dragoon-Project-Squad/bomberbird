class_name HeldPickups extends Node

enum bomb_types {DEFAULT, PIERCING, MINE, REMOTE, SEEKER}
enum exclusive {DEFAULT, KICK, BOMBTHROUGH}
enum virus {DEFAULT, SPEEDDOWN, SPEEDUP, FIREDOWN, SLOWFUSE_A, SLOWFUSE_B, FASTFUSE, AUTOBOMB, INVERSE_CONTROL, NON_STOP_MOTION, NOBOMBS, SIZE}

var count_keys: Array[String] = [
	"extra_bomb",
	"explosion_boost",
	"speed_boost",
	#"heart",
	]

var bool_keys: Array[String] = [
	"max_explosion",
	"punch_ability",
	#"throw_ability",
	#"wallthrough",
	#"timer",
	#"invincibility_vest",
	]

var enum_keys: Array[String] = [
	#"bomb_type",
	#"exclusive",
	#"virus",
	]

var held_pickups: Dictionary = {
	"bomb_type": bomb_types.DEFAULT,	#//
	"exclusive": exclusive.DEFAULT,		#Bomb Kick / Bombthrough
	"virus": virus.DEFAULT, 					#Random, counterproductive condition
	"extra_bomb": 0,									#Bomb UP
	"explosion_boost": 0,							#Fire Up
	"speed_boost": 0,									#Speed Up
	"heart": 0,												#+1 HP (max 2)
	"max_explosion": false,						#Full Fire
	"punch_ability": false,						#Bomb Punch
	"throw_ability": false,						#Power Glove
	"wallthrough": false,							#Wallthrough
	"timer": false, 									#Freezes enemies
	"invincibility_vest": false				#invulnerability
	}

func reset():
	held_pickups.bomb_type = bomb_types.DEFAULT
	held_pickups.exclusive = exclusive.DEFAULT
	held_pickups.virus = virus.DEFAULT
	held_pickups.extra_bomb = 0
	held_pickups.explosion_boost = 0
	held_pickups.speed_boost = 0
	held_pickups.heart = 0
	held_pickups.max_explosion = false
	held_pickups.punch_ability = false
	held_pickups.throw_ability = false
	held_pickups.wallthrough = false
	held_pickups.timer = false
	held_pickups.invincibility_vest = false
	

func add(pickup_type: String, virus_type: int = 0):
	if(virus_type < 0 || virus.SIZE <= virus_type):
		push_error("Invalid virus type given")
	match pickup_type:
		"piercing_bomb":
			held_pickups.bomb_type = bomb_types.PIERCING	
		"land_mine":
			held_pickups.bomb_type = bomb_types.MINE
		"remote_control":
			held_pickups.bomb_type = bomb_types.REMOTE
		"seeker_bomb":
			held_pickups.bomb_type = bomb_types.SEEKER
		"virus":
			held_pickups[pickup_type] = virus_type
		"extra_bomb":
			held_pickups[pickup_type] += 1
		"explosion_boost":
			held_pickups[pickup_type] += 1
		"speed_boost":
			held_pickups[pickup_type] += 1
		"heart":
			held_pickups[pickup_type] += 1
		"max_explosion":
			held_pickups[pickup_type] = true
		"punch_ability":
			held_pickups[pickup_type] = true
		"throw_ability":
			held_pickups[pickup_type] = true
		"kick_ability":
			held_pickups.exclusive = exclusive.KICK
		"bombthrough":
			held_pickups.exclusive = exclusive.BOMBTHROUGH
		"wallthrough":
			held_pickups[pickup_type] = true
		"timer":
			held_pickups[pickup_type] = true
		"invincibility vest":
			held_pickups[pickup_type] = true
		_:
			push_error("unknown pickup type... picked up")
