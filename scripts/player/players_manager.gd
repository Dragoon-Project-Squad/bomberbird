#Abstract Layer between world/gamestate and players
class_name PlayerManager extends Node2D

signal alive_players_changed

@onready var players_left = gamestate.total_player_count

func _init():
	globals.player_manager = self

func _ready() -> void:
	globals.game.player_manager = self
	alive_players_changed.connect(globals.game._check_ending_condition, CONNECT_DEFERRED)

func get_alive_players() -> Array[Player]:
	return get_players("alive")
	
func get_dead_players() -> Array[Player]:
	return get_players("dead")	

func get_players(type: String = "all") -> Array[Player]:
	match type:
		"all":
			return Array(get_children().filter(func (p): return (p is HumanPlayer || p is AIPlayer)), TYPE_OBJECT, "CharacterBody2D", Player)
		"dead":
			return Array(get_children().filter(func (p): return (p is HumanPlayer || p is AIPlayer) && p.is_dead), TYPE_OBJECT, "CharacterBody2D", Player)
		"alive":
			return Array(get_children().filter(func (p): return (p is HumanPlayer || p is AIPlayer) && !p.is_dead), TYPE_OBJECT, "CharacterBody2D", Player)
		_:
			return Array(get_children().filter(func (p): return (p is HumanPlayer || p is AIPlayer)), TYPE_OBJECT, "CharacterBody2D", Player)

func _on_player_died():
	#If SUPER and killer is dead he would be revived so nothing meaningfull has actualy changed
	players_left -= 1
	alive_players_changed.emit(-1)

func _on_player_revived():
	players_left += 1

func _on_hurry_up_start() -> void:
	if SettingsContainer.misobon_setting == SettingsContainer.misobon_setting_states.OFF:
		return
	for player in get_children():
		if player is MultiplayerSpawner: continue
		player.hurry_up_started = true
		if !player.is_dead: continue
		if !is_multiplayer_authority(): continue
		player.misobon_player.play_despawn_animation.rpc()
		player.misobon_player.disable.rpc(true)
