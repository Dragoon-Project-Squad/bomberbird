extends Control

const INIT_SCORE: int = 800

signal pickup_shop_next
signal pickup_shop_back

@onready var pickup_grid: GridContainer = %Pickups
@onready var exclusive_pickup_grid: GridContainer = %ExclusivePickups
@onready var bomb_upgrade_pickup_grid: GridContainer = %BombUpgrades
@onready var score_label: Label = %ScoreLabel

@export_range(0, 999999) var init_score: int = INIT_SCORE:
	set(val):
		init_score = val
		var format_string = "%06d"
		score_label.set_text(format_string % [init_score])


var pickup_buttons: Array[LRClickButton] = []
var exclusive_pickup_buttons: Array[LRClickButton] = []
var bomb_upgrade_pickup_buttons: Array[LRClickButton] = []

func _ready() -> void:
	for button in pickup_grid.get_children():
		if !(button is LRClickButton): continue
		pickup_buttons.append(button)
		button.shop = self

	for button in exclusive_pickup_grid.get_children():
		if !(button is LRClickButton): continue
		exclusive_pickup_buttons.append(button)
		button.shop = self
	for button in exclusive_pickup_grid.get_children():
		if !(button is LRClickButton): continue
		button.pickup_button_group = exclusive_pickup_buttons.duplicate()

	for button in bomb_upgrade_pickup_grid.get_children():
		if !(button is LRClickButton): continue
		bomb_upgrade_pickup_buttons.append(button)
		button.shop = self
	for button in bomb_upgrade_pickup_grid.get_children():
		if !(button is LRClickButton): continue
		button.pickup_button_group = bomb_upgrade_pickup_buttons.duplicate()

		var format_string = "%06d"
		score_label.set_text(format_string % [init_score])

func enter():
	show()
	for button in pickup_buttons:
		button.to_empty()
	for button in exclusive_pickup_buttons:
		button.to_empty()
	for button in bomb_upgrade_pickup_buttons:
		button.to_empty()
	init_score = INIT_SCORE

func _on_next_clicked():
	var init_pickups: HeldPickups = HeldPickups.new()

	for button in pickup_buttons:
		var pickup_type: int = globals.pickup_name_str.find_key(button.pickup_name)
		for _i in range(button.amount):
			init_pickups.add(pickup_type)
	for button in exclusive_pickup_buttons:
		var pickup_type: int = globals.pickup_name_str.find_key(button.pickup_name)
		for _i in range(button.amount):
			init_pickups.add(pickup_type)
	for button in bomb_upgrade_pickup_buttons:
		var pickup_type: int = globals.pickup_name_str.find_key(button.pickup_name)
		for _i in range(button.amount):
			init_pickups.add(pickup_type)
	write_to_temp_save_file(init_score, init_pickups.held_pickups)
	pickup_shop_next.emit()

func _on_back_clicked():
	pickup_shop_back.emit()

func write_to_temp_save_file(remaining_score: int, init_pickups: Dictionary):
	gamestate.current_save.player_health = 3
	gamestate.current_save.current_score = remaining_score 
	gamestate.current_save.player_pickups = init_pickups
