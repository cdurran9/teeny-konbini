extends Node

const MORALE_DRAIN_PER_TICK := 0.002
const POOL_SIZE := 3

const _NAMES := [
	"Alex", "Jordan", "Morgan", "Casey", "Riley",
	"Sam", "Taylor", "Quinn", "Avery", "Drew",
	"Jamie", "Skyler", "Reese", "Finley", "Dakota"
]
const _TRAIT_IDS := ["friendly", "fast", "reliable"]

var hiring_pool: Array[Dictionary] = []

func _ready():
	EventBus.tick_processed.connect(_on_tick)
	EventBus.prestige_completed.connect(_on_prestige_completed)
	_replenish_pool()

func _on_prestige_completed():
	hiring_pool.clear()
	_replenish_pool()

func _on_tick(_tick: Dictionary):
	_drain_morale()
	_replenish_pool()

func _drain_morale():
	var quitters: Array[Dictionary] = []
	for staff in GameState.hired_staff:
		staff["morale"] -= MORALE_DRAIN_PER_TICK
		if staff["morale"] <= 0.0:
			quitters.append(staff)
	for staff in quitters:
		GameState.hired_staff.erase(staff)
		EventBus.staff_quit.emit(staff)

func _replenish_pool():
	while hiring_pool.size() < POOL_SIZE:
		hiring_pool.append(_generate_staff())

func _generate_staff() -> Dictionary:
	var shuffled := _TRAIT_IDS.duplicate()
	shuffled.shuffle()
	var count := randi_range(1, 2)
	var traits: Array[String] = []
	for i in range(count):
		traits.append(shuffled[i])
	return {
		"id": str(randi()),
		"display_name": _NAMES[randi() % _NAMES.size()],
		"traits": traits,
		"assigned_store_idx": -1,
		"morale": 1.0
	}

func hire(pool_idx: int) -> bool:
	if pool_idx < 0 or pool_idx >= hiring_pool.size():
		return false
	var staff: Dictionary = hiring_pool[pool_idx]
	hiring_pool.remove_at(pool_idx)
	GameState.hired_staff.append(staff)
	EventBus.staff_hired.emit(staff)
	return true

func assign(staff_id: String, store_idx: int):
	for staff in GameState.hired_staff:
		if staff["id"] == staff_id:
			staff["assigned_store_idx"] = store_idx
			return
