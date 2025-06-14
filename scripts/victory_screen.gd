extends Control

func _ready() -> void:
	var player_scores = gamestate.get_player_scores()
	var textures = gamestate.get_player_texture_list()
	var player_names = gamestate.get_player_name_list()
	var sorted_player_id_by_score = sort_player_ids_by_score(player_scores)
	set_player_texture(sorted_player_id_by_score, textures, player_names)
	
	if is_multiplayer_authority():
		globals.game.free()
		remove_game_node.rpc()
	
	$AnimationPlayer.play("fade_in")
	var anim  : Animation= $Control/AnimationPlayer1.get_animation("victory")
	anim.loop_mode =(Animation.LOOP_LINEAR)
	$Control/AnimationPlayer1.play("victory")
	if $"Control/4th".visible:
		$Control/AnimationPlayer2.play("cry")

@rpc("call_remote")
func remove_game_node():
	globals.game.queue_free()

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

func set_player_texture(score_sorted_pids, player_textures, player_names) -> void:
	$Label.text = "The winner is " + player_names[score_sorted_pids[0]]
	for i in score_sorted_pids.size():
		match i:
			0:
				$"Control/1st".texture = load(player_textures[score_sorted_pids[0]].walk)
				$"Control/1st/Label".text = player_names[score_sorted_pids[0]]
			1:
				$"Control/2nd".texture = load(player_textures[score_sorted_pids[1]].walk)
				$"Control/2nd/Label".text = player_names[score_sorted_pids[1]]
			2:
				$"Control/3rd".texture = load(player_textures[score_sorted_pids[2]].walk)
				$"Control/3rd/Label".text = player_names[score_sorted_pids[2]]
			3:
				$"Control/4th".texture = load(player_textures[score_sorted_pids[3]].walk)
				$"Control/4th/Label".text = player_names[score_sorted_pids[3]]
	show_positions(score_sorted_pids.size())

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
	
func _on_timer_timeout():
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	gamestate.end_game()
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
	gamestate.player_list_changed.emit()
