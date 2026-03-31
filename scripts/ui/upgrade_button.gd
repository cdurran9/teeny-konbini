extends Button
class_name UpgradeButton

var def: UpgradeDef

func _init(_def: UpgradeDef):
	def = _def

func _ready():
	EventBus.upgrade_purchased.connect(on_upgrade_purchased)
	
func on_upgrade_purchased(id: String):
	if id == def.id:
		disabled = true
