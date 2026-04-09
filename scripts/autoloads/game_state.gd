extends Node

const SAVE_PATH := "user://prestige.cfg"
const PRESTIGE_STORE_THRESHOLD := 3
const PRESTIGE_REP_THRESHOLD := 50.0

@export var starting_money := 0.0
@export var prestige_enabled := true

var current_money := 0.0
var brand_reputation := 0.0
var brand_identity_id: String = ""
# Each entry: { "location_id": String, "local_reputation": float }
var owned_stores: Array[Dictionary] = []
var owned_upgrades: Array[String] = []
var owned_products: Array[String] = []
var hired_staff: Array[Dictionary] = []
var product_upgrades: Dictionary = {}
var legacy_points: int = 0

var _prestige_signaled := false

func _ready():
	_load_legacy_points()
	current_money = starting_money
	owned_stores = [ {"location_id": "strip_mall", "local_reputation": 1.0}]
	EventBus.tick_processed.connect(_apply_tick)
	DevConsole.register("add_money", _cmd_add_money)
	DevConsole.register("set_money", _cmd_set_money)
	DevConsole.register("set_rep", _cmd_set_rep)

func _apply_tick(tick: Dictionary):
	current_money += tick.income
	brand_reputation += tick.reputation_gain
	EventBus.money_changed.emit(current_money)
	EventBus.reputation_changed.emit(brand_reputation)
	if prestige_enabled and not _prestige_signaled and _prestige_threshold_met():
		_prestige_signaled = true
		EventBus.prestige_available.emit()

func _prestige_threshold_met() -> bool:
	return owned_stores.size() >= PRESTIGE_STORE_THRESHOLD and brand_reputation >= PRESTIGE_REP_THRESHOLD

func purchase_upgrade(id: String):
	var def: UpgradeDef = UpgradeRegistry._upgrades.get(id)
	if not def or owned_upgrades.has(id):
		return
	if current_money < def.base_cost:
		return
	for prereq in def.prerequisites:
		if not owned_upgrades.has(prereq):
			return
	current_money -= def.base_cost
	EventBus.money_changed.emit(current_money)
	for effect in def.effects:
		effect.on_purchase()
	owned_upgrades.append(id)
	EventBus.upgrade_purchased.emit(id)

func purchase_product(id: String):
	if UpgradeRegistry._products.get(id) and not owned_products.has(id):
		owned_products.append(id)
		EventBus.product_purchased.emit(id)

func apply_product_upgrade(product_id: String):
	var new_level: int = product_upgrades.get(product_id, 0) + 1
	product_upgrades[product_id] = new_level
	EventBus.product_upgraded.emit(product_id, new_level)

func choose_brand(brand_id: String):
	brand_identity_id = brand_id
	EventBus.brand_chosen.emit(brand_id)

func open_store(location_id: String):
	var location: LocationDef = UpgradeRegistry._locations.get(location_id)
	if not location:
		return
	if brand_reputation < location.reputation_requirement:
		return
	for store in owned_stores:
		if store.location_id == location_id:
			return
	owned_stores.append({"location_id": location_id, "local_reputation": 1.0})
	EventBus.store_opened.emit(location_id)

func prestige():
	if not prestige_enabled:
		return
	legacy_points += 1
	_save_legacy_points()
	current_money = starting_money
	brand_reputation = 0.0
	brand_identity_id = ""
	owned_stores = [ {"location_id": "strip_mall", "local_reputation": 1.0}]
	owned_upgrades = []
	owned_products = []
	hired_staff = []
	product_upgrades = {}
	_prestige_signaled = false
	EventBus.prestige_completed.emit()
	get_tree().reload_current_scene()

func add_money(amount: float) -> void:
	current_money += amount
	EventBus.money_changed.emit(current_money)

func _cmd_add_money(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Usage: add_money <amount>"
	add_money(float(args[0]))
	return ""

func _cmd_set_money(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Usage: set_money <amount>"
	current_money = float(args[0])
	EventBus.money_changed.emit(current_money)
	return ""

func _cmd_set_rep(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Usage: set_rep <amount>"
	brand_reputation = float(args[0])
	EventBus.reputation_changed.emit(brand_reputation)
	return ""

func _load_legacy_points():
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		legacy_points = cfg.get_value("prestige", "legacy_points", 0)

func _save_legacy_points():
	var cfg := ConfigFile.new()
	cfg.set_value("prestige", "legacy_points", legacy_points)
	cfg.save(SAVE_PATH)
