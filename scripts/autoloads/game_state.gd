extends Node

@export var starting_money := 0.0

var current_money := 0.0
var brand_reputation := 0.0
var brand_identity_id: String = ""
# Each entry: { "location_id": String, "local_reputation": float }
var owned_stores: Array[Dictionary] = []
var owned_upgrades: Array[String] = []
var owned_products: Array[String] = []
var hired_staff: Array[Dictionary] = []

func _ready():
	current_money = starting_money
	owned_stores = [{ "location_id": "strip_mall", "local_reputation": 1.0 }]
	EventBus.tick_processed.connect(_apply_tick)

func _apply_tick(tick: Dictionary):
	current_money += tick.income
	brand_reputation += tick.reputation_gain
	EventBus.money_changed.emit(current_money)
	EventBus.reputation_changed.emit(brand_reputation)

func purchase_upgrade(id: String):
	var def: UpgradeDef = UpgradeRegistry._upgrades.get(id)
	if def and not owned_upgrades.has(id):
		for effect in def.effects:
			effect.on_purchase()
		owned_upgrades.append(id)
		EventBus.upgrade_purchased.emit(id)

func purchase_product(id: String):
	if UpgradeRegistry._products.get(id) and not owned_products.has(id):
		owned_products.append(id)

func open_store(location_id: String):
	var location: LocationDef = UpgradeRegistry._locations.get(location_id)
	if not location:
		return
	if brand_reputation < location.reputation_requirement:
		return
	for store in owned_stores:
		if store.location_id == location_id:
			return
	owned_stores.append({ "location_id": location_id, "local_reputation": 1.0 })
	EventBus.store_opened.emit(location_id)
