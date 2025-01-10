extends CharacterBody2D
@onready var breakable_sfx_player := $BreakableSound

@rpc("call_local")
func exploded(_by_who):
	breakable_sfx_player.play()
	#$"../../Score".increase_score(by_who) Rocks don't count for score
	$"AnimationPlayer".play("explode")
	# Spawn a powerup where this rock used to be.
	get_node("/root/World/PickupSpawner").spawn(self.position)
	await $"AnimationPlayer".animation_finished #Wait for the animation to finish
	queue_free()
