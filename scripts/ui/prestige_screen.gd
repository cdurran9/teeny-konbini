extends CanvasLayer

func _ready():
	visible = false
	EventBus.prestige_available.connect(_on_prestige_available)

func _on_prestige_available():
	_build_screen()
	visible = true

func _build_screen():
	for child in get_children():
		child.queue_free()

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(500, 320)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Ready to Prestige!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var stats := Label.new()
	stats.text = "Money: $%.0f  |  Rep: %.1f  |  Stores: %d\nLegacy Points after prestige: %d → %d" % [
		GameState.current_money,
		GameState.brand_reputation,
		GameState.owned_stores.size(),
		GameState.legacy_points,
		GameState.legacy_points + 1
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)

	var bonus_header := Label.new()
	bonus_header.text = "Active legacy bonuses:"
	bonus_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(bonus_header)

	for bonus in UpgradeRegistry._legacy_bonuses.values():
		var lp_needed: int = bonus.required_legacy_points
		var next_lp := GameState.legacy_points + 1
		var active_now := GameState.legacy_points >= lp_needed
		var active_next := next_lp >= lp_needed
		var status := ""
		if active_now:
			status = "[active]"
		elif active_next:
			status = "[unlocks this prestige!]"
		else:
			status = "[requires %d LP]" % lp_needed
		var lbl := Label.new()
		lbl.text = "  %s %s" % [bonus.display_name, status]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

	var prestige_btn := Button.new()
	prestige_btn.text = "Prestige (+1 Legacy Point)"
	prestige_btn.custom_minimum_size = Vector2(480, 50)
	prestige_btn.pressed.connect(func(): GameState.prestige())
	vbox.add_child(prestige_btn)

	var not_yet_btn := Button.new()
	not_yet_btn.text = "Not yet — keep building"
	not_yet_btn.custom_minimum_size = Vector2(480, 40)
	not_yet_btn.pressed.connect(func(): visible = false)
	vbox.add_child(not_yet_btn)
