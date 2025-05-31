class_name EnemyPool extends ObjectPool

func _ready():
	globals.game.enemy_pool = self
	obj_spawner = get_node("EnemySpawner")
	unowned = {}
	super()

func initialize(enemy_dict: Dictionary):
	for enemy in enemy_dict.keys():
		create_reserve(enemy_dict[enemy], enemy)

func create_reserve(count: int, enemy_path: String): #creates a number of unowned obj's for the pool
	if !is_multiplayer_authority():
		return
	unowned[enemy_path] = []
	unowned[enemy_path].resize(count)
	for i in range(count):
		unowned[enemy_path][i] = obj_spawner.spawn(enemy_path)

func request(enemy_path: String) -> Enemy:
	var enemy: Enemy = null
	if unowned.has(enemy_path):
		enemy = unowned[enemy_path].pop_front()
		
	if enemy == null: #no obj hence spawn one
		enemy = obj_spawner.spawn(enemy_path)
		
	return enemy 

func request_group(enemy_dict: Dictionary, _void: int = 0) -> Dictionary:
	var return_dict: Dictionary = {}

	for enemy_path in enemy_dict:
		if enemy_dict[enemy_path] <= 0: continue
		
		var count: int = enemy_dict[enemy_path]
		
		var take: int = 0
		if unowned.has(enemy_path):
			take = min(count, unowned[enemy_path].size())
		return_dict[enemy_path] = []
		for _i in range(take):
			return_dict[enemy_path].push_back(unowned[enemy_path].pop_front())

		for _i in range(count - return_dict[enemy_path].size()):
			return_dict[enemy_path].push_back(obj_spawner.spawn(enemy_path))

	return return_dict

func return_obj(enemy: Enemy) -> void:
	assert(enemy, "null was attempted to be returned to the pickup_pool")
	assert(!enemy.visible)
	assert(enemy.position == Vector2.ZERO)
	if !unowned.has(enemy.enemy_path):
		unowned[enemy.enemy_path] = []
	assert(!(enemy in unowned[enemy.enemy_path]))
	unowned[enemy.enemy_path].push_back(enemy)

func return_obj_group(enemy_dict : Dictionary) -> void:
	for enemy_path in enemy_dict.keys():
		assert(enemy_dict[enemy_path].all(func (e: Enemy): return e != null), "null was attempted to be returned to the pickup_pool")
		assert(enemy_dict[enemy_path].all(func (e: Enemy): return !e.visible))
		assert(enemy_dict[enemy_path].all(func (e: Enemy): return e.position == Vector2.ZERO))
		if !unowned.has(enemy_path):
			unowned[enemy_path] = []
			
		unowned[enemy_path].append_array(enemy_dict[enemy_path])
