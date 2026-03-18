extends Node

@export var starting_money := 0
@export var starting_shops := 1

var current_money := 0
var current_shops_count := 1
var owned_upgrades: Array[String] = []
var owned_products: Array[String] = []

func _ready():
	current_money = starting_money
	current_shops_count = starting_shops
	EventBus.tick_processed.connect(_apply_tick)

func _apply_tick(tick: Dictionary):
	current_money += tick.change_amount
	EventBus.money_changed.emit(current_money)

func purchase_upgrade(id: String):
	if UpgradeRegistry._upgrades.get(id) and not owned_upgrades.has(id):
		owned_upgrades.append(id)
		
func purchase_product(id: String):
	if UpgradeRegistry._products.get(id) and not owned_products.has(id):
		owned_products.append(id)
