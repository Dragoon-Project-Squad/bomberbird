extends LRClickButton

@onready var amount_label: Label = %Amount
@onready var max_amount_label: Label = %MaxAmount
@onready var price_label: Label = %Price
@onready var amounts: Control = $Amounts

@export_range(1, 9) var max_amount: int = 0:
	set(val):
		max_amount = val
		set_max_amount(max_amount)

var shop: Control = null

@export_enum(
	"extra_bomb",
	"explosion_boost",
	"speed_boost",
	"hearth",
	"max_explosion",
	"punch_ability",
	"throw_ability",
	"wallthrough",
	"kick",
	"bombthrough",
	"piercing_bomb",
	"land_mine",
	"remote_control",
	"seeker_bomb",
	"mount_goon",
	"no_pickup",
	) var pickup_name: String = "extra_bomb":
		set(val):
			pickup_name = val
			if val == "no_pickup":
				self.icon = null
			else:
				if self.icon == null:
					self.icon = AtlasTexture.new()
					self.icon.atlas = load("res://assets/pickups/powerupsprites.png")
				set_icon(globals.pickup_name_region[val])

@export_range(0, 99999) var price: int = 100:
	set(val):
		price = val
		set_price(price)

var amount: int = 0:
	set(val):
		if val < 0 || val > max_amount:
			indicate_failure()
			return
		amount = val
		set_amount(amount)

var pickup_button_group: Array[LRClickButton] = [self]

func _ready() -> void:
	disable_amounts()
	set_amount(amount)
	set_max_amount(max_amount)
	set_price(price)
	if pickup_name == "no_pickup":
		self.icon = null
	else:
		if self.icon == null:
			self.icon = AtlasTexture.new()
			self.icon.atlas = load("res://assets/pickups/powerupsprites.png")
		set_icon(globals.pickup_name_region[pickup_name])

func set_icon(rect: Rect2i):
	assert(self.icon is AtlasTexture)
	assert(rect.size.x == 24)
	assert(rect.size.y == 24)
	self.icon.region = rect

func set_price(some_price: int):
	if price_label:
		price_label.set_text(str(some_price))

func disable_amounts():
	amounts.hide()
	self.self_modulate = Color.WHITE

func enable_amounts():
	amounts.show()
	self.self_modulate = Color.DARK_GRAY

func set_amount(new_amount: int):
	if amount_label:
		amount_label.set_text(str(new_amount))
	if new_amount > 0:
		enable_amounts()
	else:
		disable_amounts()

func set_max_amount(new_max_amount: int):
	if max_amount_label:
		max_amount_label.set_text(str(new_max_amount))

func indicate_failure() -> void:
	$AnimationPlayer.play("failure")

func can_exclusice_switch() -> bool:
	var excluding_score: int = shop.init_score
	for button in self.pickup_button_group:
		if button == self: continue
		if button.amount > 0: excluding_score += button.price * button.amount
	return excluding_score < self.price

func _on_left_pressed() -> void:
	if shop && can_exclusice_switch():
		indicate_failure()
		return
	if shop && amount < max_amount: shop.init_score -= self.price
	amount += 1
	for button in self.pickup_button_group:
		if button == self: continue
		if shop && button.amount > 0: shop.init_score += button.price * button.amount
		button.to_empty()


func _on_right_pressed() -> void:
	if shop && amount > 0: shop.init_score += self.price
	amount -= 1

func to_empty():
	self.amount = 0
