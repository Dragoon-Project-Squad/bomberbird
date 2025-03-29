#Abstract Layer between world/gamestate and players
#TODO: Move player related functions (evtl as static) from world and/or gamestate into here
class_name PlayerManager extends Node2D

signal alive_players_changed

@onready var players_left = gamestate.total_player_count

func _init():
	globals.player_manager = self

func _ready() -> void:
	globals.game.player_manager = self
	alive_players_changed.connect(globals.game._check_ending_condition, CONNECT_DEFERRED)

func get_alive_players() -> Array[Player]:
	var alive_players: Array[Player] = []
	for player in get_children():
		if !(player is HumanPlayer) && !(player is AIPlayer): continue
		if player.is_dead: continue
		alive_players.append(player)
	return alive_players

func _on_player_died():
	#If SUPER and killer is dead he would be revived so nothing meaningfull has actualy changed
	players_left -= 1
	#TODO: pass actuall alive enemy number to this emit
	alive_players_changed.emit(0)

func _on_player_revived():
	players_left += 1


func _on_hurry_up_start() -> void:
	if gamestate.misobon_mode == gamestate.misobon_states.OFF:
		return
	for player in get_children():
		if player is MultiplayerSpawner: continue
		player.hurry_up_started = true
		if !player.is_dead: continue
		if !is_multiplayer_authority(): continue
		player.misobon_player.play_despawn_animation.rpc()
		player.misobon_player.disable.rpc(true)
