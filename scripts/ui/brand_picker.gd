extends CanvasLayer

func _ready():
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 300)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Choose Your Brand Identity"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	for brand_id in UpgradeRegistry._brands:
		var brand: BrandIdentityDef = UpgradeRegistry._brands[brand_id]
		var btn := Button.new()
		btn.text = "%s\n%s" % [brand.display_name, brand.description]
		btn.custom_minimum_size = Vector2(380, 60)
		btn.pressed.connect(func(): _choose(brand.id))
		vbox.add_child(btn)

func _choose(brand_id: String):
	GameState.choose_brand(brand_id)
	queue_free()
