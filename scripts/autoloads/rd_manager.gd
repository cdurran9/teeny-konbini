extends Node

const RESEARCH_COST := 50.0
const RESEARCH_DURATION_TICKS := 10
const PITY_THRESHOLD := 3
const MAX_UPGRADE_LEVEL := 3
const CHOICES_COUNT := 3

var is_researching := false
var ticks_remaining := 0
var pity_counter := 0
var pending_choices: Array[Dictionary] = []

func _ready():
	EventBus.tick_processed.connect(_on_tick)

func start_research() -> bool:
	if is_researching or not pending_choices.is_empty():
		return false
	if GameState.current_money < RESEARCH_COST:
		return false
	GameState.current_money -= RESEARCH_COST
	EventBus.money_changed.emit(GameState.current_money)
	is_researching = true
	ticks_remaining = RESEARCH_DURATION_TICKS
	return true

func _on_tick(_tick: Dictionary):
	if not is_researching:
		return
	ticks_remaining -= 1
	if ticks_remaining <= 0:
		_complete_research()

func _complete_research():
	is_researching = false
	var choices := _roll_choices()
	if choices.is_empty():
		return
	pending_choices = choices
	EventBus.research_completed.emit(choices)

func choose(choice: Dictionary):
	if pending_choices.is_empty():
		return
	_apply_choice(choice)
	pending_choices.clear()

func _apply_choice(choice: Dictionary):
	match choice["type"]:
		"unlock_product":
			GameState.purchase_product(choice["id"])
		"upgrade_product":
			var pid: String = choice["id"]
			var current_level: int = GameState.product_upgrades.get(pid, 0)
			GameState.product_upgrades[pid] = current_level + 1

func _build_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	for product_id in UpgradeRegistry._products:
		if not GameState.owned_products.has(product_id):
			var product: ProductDefinition = UpgradeRegistry._products[product_id]
			pool.append({
				"type": "unlock_product",
				"id": product_id,
				"display_name": "Unlock: %s" % product.display_name
			})

	for product_id in GameState.owned_products:
		var level: int = GameState.product_upgrades.get(product_id, 0)
		if level < MAX_UPGRADE_LEVEL:
			var product: ProductDefinition = UpgradeRegistry._products.get(product_id)
			if product:
				pool.append({
					"type": "upgrade_product",
					"id": product_id,
					"display_name": "Upgrade: %s (Lv.%d→%d)" % [product.display_name, level, level + 1]
				})

	return pool

func _roll_choices() -> Array[Dictionary]:
	var pool := _build_pool()
	if pool.is_empty():
		return []

	var unlock_pool: Array[Dictionary] = []
	var upgrade_pool: Array[Dictionary] = []
	for item in pool:
		if item["type"] == "unlock_product":
			unlock_pool.append(item)
		else:
			upgrade_pool.append(item)

	var choices: Array[Dictionary] = []

	if pity_counter >= PITY_THRESHOLD and not unlock_pool.is_empty():
		# Guaranteed new unlock
		unlock_pool.shuffle()
		choices.append(unlock_pool[0])
		pity_counter = 0
		var rest: Array[Dictionary] = unlock_pool.slice(1) + upgrade_pool
		rest.shuffle()
		var fill := mini(CHOICES_COUNT - 1, rest.size())
		for i in range(fill):
			choices.append(rest[i])
	else:
		pool.shuffle()
		var count := mini(CHOICES_COUNT, pool.size())
		for i in range(count):
			choices.append(pool[i])
		var has_unlock := false
		for c in choices:
			if c["type"] == "unlock_product":
				has_unlock = true
				break
		if not has_unlock:
			pity_counter += 1

	return choices
