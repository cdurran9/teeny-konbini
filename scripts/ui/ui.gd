extends Control
@onready var label = $Label
@onready var reputation_label = $ReputationLabel
@onready var buttons_horizontal = $ButtonsHorizontal
@onready var locations_container = $LocationsContainer
@onready var staff_container = $StaffContainer
@onready var rd_container = $RdContainer

func _ready():
	EventBus.money_changed.connect(update_score)
	EventBus.reputation_changed.connect(update_reputation)
	EventBus.store_opened.connect(_on_store_opened)
	EventBus.staff_hired.connect(_on_staff_changed)
	EventBus.staff_quit.connect(_on_staff_changed)
	EventBus.tick_processed.connect(_on_tick_for_rd)
	EventBus.research_completed.connect(_on_research_completed)
	build_buttons_display()
	build_locations_display()
	build_staff_display()
	build_rd_display()
	update_score(GameState.current_money)
	update_reputation(GameState.brand_reputation)

func update_score(new_score: float):
	var next := "%.2f" % new_score
	for idx in range(next.find(".") - 3, 0, -3):
		next = next.insert(idx, ",")
	next = '$' + next
	label.text = next

func update_reputation(new_rep: float):
	reputation_label.text = "Rep: %.1f" % new_rep
	# refresh location buttons so gating reflects current reputation
	for child in locations_container.get_children():
		child.queue_free()
	build_locations_display()

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

func build_locations_display():
	var owned_ids := GameState.owned_stores.map(func(s): return s.location_id)
	for location_id in UpgradeRegistry._locations:
		if owned_ids.has(location_id):
			continue
		var loc: LocationDef = UpgradeRegistry._locations[location_id]
		var can_open := GameState.brand_reputation >= loc.reputation_requirement
		var btn := Button.new()
		btn.text = "%s (Rep: %.0f)" % [loc.display_name, loc.reputation_requirement]
		btn.disabled = not can_open
		btn.pressed.connect(func(): GameState.open_store(loc.id))
		locations_container.add_child(btn)

func _on_store_opened(_location_id: String):
	for child in locations_container.get_children():
		child.queue_free()
	build_locations_display()

func _on_staff_changed(_staff: Dictionary):
	build_staff_display()

func build_staff_display():
	for child in staff_container.get_children():
		child.queue_free()

	var pool_label := Label.new()
	pool_label.text = "--- Hiring Pool ---"
	staff_container.add_child(pool_label)

	for i in range(StaffManager.hiring_pool.size()):
		var staff: Dictionary = StaffManager.hiring_pool[i]
		var traits_str := ", ".join(PackedStringArray(staff["traits"]))
		var btn := Button.new()
		btn.text = "Hire %s [%s]" % [staff["display_name"], traits_str]
		var idx := i
		btn.pressed.connect(func():
			StaffManager.hire(idx)
			build_staff_display()
		)
		staff_container.add_child(btn)

	var hired_label := Label.new()
	hired_label.text = "--- Hired Staff ---"
	staff_container.add_child(hired_label)

	if GameState.hired_staff.is_empty():
		var none_label := Label.new()
		none_label.text = "(none)"
		staff_container.add_child(none_label)
		return

	for staff in GameState.hired_staff:
		var traits_str := ", ".join(PackedStringArray(staff["traits"]))
		var morale_pct := int(staff["morale"] * 100)
		var store_info := "Unassigned" if staff["assigned_store_idx"] < 0 else "Store %d" % staff["assigned_store_idx"]
		var lbl := Label.new()
		lbl.text = "%s [%s] — %s | Morale: %d%%" % [staff["display_name"], traits_str, store_info, morale_pct]
		staff_container.add_child(lbl)

		for store_idx in range(GameState.owned_stores.size()):
			var loc_id: String = GameState.owned_stores[store_idx]["location_id"]
			var assign_btn := Button.new()
			assign_btn.text = "  → Store %d (%s)" % [store_idx, loc_id]
			var sid: String = staff["id"]
			assign_btn.pressed.connect(func():
				StaffManager.assign(sid, store_idx)
				build_staff_display()
			)
			staff_container.add_child(assign_btn)

func _on_tick_for_rd(_tick: Dictionary):
	if RdManager.is_researching:
		build_rd_display()

func _on_research_completed(_choices: Array):
	build_rd_display()

func build_rd_display():
	for child in rd_container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "--- R&D Lab ---"
	rd_container.add_child(header)

	if not RdManager.pending_choices.is_empty():
		var prompt := Label.new()
		prompt.text = "Research complete! Choose one:"
		rd_container.add_child(prompt)
		for choice in RdManager.pending_choices:
			var btn := Button.new()
			btn.text = choice["display_name"]
			var c: Dictionary = choice
			btn.pressed.connect(func():
				RdManager.choose(c)
				build_rd_display()
			)
			rd_container.add_child(btn)
		return

	if RdManager.is_researching:
		var status := Label.new()
		status.text = "Researching... (%d ticks left)" % RdManager.ticks_remaining
		rd_container.add_child(status)
	else:
		var start_btn := Button.new()
		start_btn.text = "Start Research ($%.0f)" % RdManager.RESEARCH_COST
		start_btn.disabled = GameState.current_money < RdManager.RESEARCH_COST
		start_btn.pressed.connect(func():
			RdManager.start_research()
			build_rd_display()
		)
		rd_container.add_child(start_btn)

	if RdManager.pity_counter > 0:
		var pity_lbl := Label.new()
		pity_lbl.text = "Pity: %d/%d" % [RdManager.pity_counter, RdManager.PITY_THRESHOLD]
		rd_container.add_child(pity_lbl)
