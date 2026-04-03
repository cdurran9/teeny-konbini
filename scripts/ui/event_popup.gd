extends CanvasLayer

var _current_event = null
var _panel: Panel = null

func _ready():
	visible = false
	EventBus.event_triggered.connect(_on_event_triggered)

func _on_event_triggered(event):
	_current_event = event
	_build_popup(event)
	visible = true

func _build_popup(event):
	if _panel:
		_panel.free()
		_panel = null

	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(480, 260)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = event.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = event.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.custom_minimum_size = Vector2(460, 0)
	vbox.add_child(desc)

	for i in range(event.choices.size()):
		var choice: EventChoice = event.choices[i]
		var duration_str := "permanent" if choice.duration_ticks == -1 else "%d ticks" % choice.duration_ticks
		var btn := Button.new()
		btn.text = "%s — %s (%s)" % [choice.label, choice.description, duration_str]
		btn.custom_minimum_size = Vector2(460, 50)
		var idx := i
		btn.pressed.connect(func(): _choose(idx))
		vbox.add_child(btn)

func _choose(choice_index: int):
	EventManager.resolve(_current_event, choice_index)
	_current_event = null
	visible = false
