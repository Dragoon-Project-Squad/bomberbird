extends Zone

@export_range(0, 1) var base_breakable_chance: float

var rng = RandomNumberGenerator.new()

func _generate_breakables():
	if not is_multiplayer_authority():
		return

	
