extends Control

func _ready() -> void:
	var ui_player_data = globals.game.game_ui.player_labels
	var textures = gamestate.characters
	var player_names = gamestate.players.duplicate()
	player_names[1] = gamestate.host_player_name 
	globals.game.queue_free()
	var sorted_player_id_by_score = sort_player_ids_by_score(ui_player_data)
	set_player_texture.rpc(sorted_player_id_by_score, textures, player_names)
	
	$AnimationPlayer.play("fade_in")
	var anim  : Animation= $Control/AnimationPlayer1.get_animation("victory")
	anim.loop_mode =(Animation.LOOP_LINEAR)
	$Control/AnimationPlayer1.play("victory")
	if $"Control/4th".visible:
		$Control/AnimationPlayer2.play("cry")

func sort_player_ids_by_score(player_scores) -> Array:
	var sorted_player_id_by_score = []
	
	for player_id in player_scores.keys():
		if sorted_player_id_by_score.is_empty():
			sorted_player_id_by_score.append(player_id)
			continue
		
		for i in sorted_player_id_by_score.size():
			if player_scores[player_id] > player_scores[sorted_player_id_by_score[i]]:
				sorted_player_id_by_score.insert(i, player_id)
				break
			
			if i == sorted_player_id_by_score.size()-1:
				sorted_player_id_by_score.append(player_id)
	
	return sorted_player_id_by_score

@rpc("call_local")
func set_player_texture(player_ids, textures, gs_players) -> void:
	$Label.text = "The winner is " + gs_players[player_ids[0]]
	for i in player_ids.size():
		match i:
			0:
				$"Control/1st".texture = load(textures[player_ids[0]])
				$"Control/1st/Label".text = gs_players[player_ids[0]]
			1:
				$"Control/2nd".texture = load(textures[player_ids[1]])
				$"Control/2nd/Label".text = gs_players[player_ids[1]]
			2:
				$"Control/3rd".texture = load(textures[player_ids[2]])
				$"Control/3rd/Label".text = gs_players[player_ids[2]]
			3:
				$"Control/4th".texture = load(textures[player_ids[3]])
				$"Control/4th/Label".text = gs_players[player_ids[3]]
	show_positions(player_ids.size())

func show_positions(number_of_players: int):
	if number_of_players <= 0:
		push_error("No players detected!")
		$Label.text = "NO CONTEST"
	if number_of_players > 3:
		$"Control/4th".show()
		$Control/Kaboom.show()
		$Control/Puddle.show()
	if number_of_players > 2:
		$"Control/3rd".show()
	if number_of_players > 1:
		$"Control/2nd".show()
	if number_of_players > 0:
		$"Control/1st".show()
		
@rpc("call_local")
func _on_timer_timeout():
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	gamestate.end_game()
	if gamestate.peer:
		gamestate.peer.close()
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
	gamestate.player_list_changed.emit()
