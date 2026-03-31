extends Control
@onready var label = $Label
@onready var buttons_horizontal = $ButtonsHorizontal

func _ready():
	EventBus.money_changed.connect(update_score)
	build_buttons_display()
	update_score(GameState.current_money)

func update_score(new_score: float):
	var next := "%.2f" % new_score
	for idx in range(next.find(".") - 3, 0, -3):
		next = next.insert(idx, ",")
	next = '$' + next
	label.text = next
	
func on_click(sig):
	print(sig)
	GameState.purchase_upgrade(sig)

func build_buttons_display():
	var buttons: Dictionary = {}
	var upgrades := UpgradeRegistry._upgrades
	for upgrade_id in upgrades:
		var def: UpgradeDef = UpgradeRegistry._upgrades.get(upgrade_id)
		var is_top := def.prerequisites.is_empty()
		var parent_key := def.id if is_top else def.prerequisites[0]
		if buttons.has(parent_key):
			var button_values: Array = buttons.get(parent_key)
			if is_top:
				button_values.push_front(def)
			else:
				button_values.push_back(def)
			buttons.set(parent_key, button_values)
		else:
			buttons.set(parent_key, [def])
	for button_id in buttons:
		var defs: Array[UpgradeDef] = []
		defs.assign(buttons.get(button_id))
		var VBox = VBoxContainer.new()
		buttons_horizontal.add_child(VBox)
		for button_def in defs:
			var button := UpgradeButton.new(button_def)
			button.text = "%s ($%.2f)" % [button_def.display_name, button_def.base_cost]
			button.pressed.connect(func(): on_click(button_def.id))
			VBox.add_child(button)
