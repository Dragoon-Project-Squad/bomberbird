#Abstract Layer between world/gamestate and players
#TODO: Move player related functions (evtl as static) from world and/or gamestate into here
class_name PlayerManager extends Node2D

@onready var players: Array = get_children()

func _init():
	globals.player_manager = self

func _on_hurry_up_start() -> void:
	if players.is_empty():
		players = get_children()
	if gamestate.misobon_mode == gamestate.misobon_states.OFF:
		return
	for player in players:
		player.hurry_up_started = true
		if !player.is_dead: continue
		if !is_multiplayer_authority(): continue
		player.misobon_player.play_despawn_animation.rpc()
		player.misobon_player.disable.rpc(true)
