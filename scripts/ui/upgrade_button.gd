extends Button
class_name UpgradeButton

var def: UpgradeDef

func _init(_def: UpgradeDef):
	def = _def

func _ready():
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.money_changed.connect(_on_money_changed)
	_refresh()

func _on_upgrade_purchased(id: String):
	if id == def.id:
		disabled = true
		return
	# A prerequisite may have just been fulfilled
	if def.prerequisites.has(id):
		_refresh()

func _on_money_changed(_new_money: float):
	_refresh()

func _refresh():
	if GameState.owned_upgrades.has(def.id):
		disabled = true
		return
	var prereqs_met := def.prerequisites.all(
		func(p): return GameState.owned_upgrades.has(p)
	)
	disabled = not prereqs_met or GameState.current_money < def.base_cost
