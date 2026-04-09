extends CanvasLayer

var _commands: Dictionary = {}

var _panel: Panel
var _output: Label
var _text_input: LineEdit

func _ready() -> void:
	layer = 128
	visible = false

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -72
	_panel.offset_bottom = 0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	_output = Label.new()
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_output.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_output)

	_text_input = LineEdit.new()
	_text_input.placeholder_text = "command [args...]"
	_text_input.add_theme_font_size_override("font_size", 14)
	_text_input.text_submitted.connect(_on_submit)
	vbox.add_child(_text_input)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			visible = not visible
			if visible:
				_text_input.grab_focus()
				_text_input.clear()
			get_viewport().set_input_as_handled()

## Register a command callable. The callable receives a PackedStringArray of
## the arguments after the keyword (all as strings — parse as needed).
## Example: DevConsole.register("add_money", _cmd_add_money)
func register(keyword: String, callable: Callable) -> void:
	_commands[keyword] = callable

func _on_submit(text: String) -> void:
	_text_input.clear()
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	var parts := trimmed.split(" ", false)
	var keyword: String = parts[0]
	var args := parts.slice(1)
	if not _commands.has(keyword):
		_set_output("Unknown command: %s" % keyword, true)
		return
	var result = _commands[keyword].call(args)
	if result is String and not result.is_empty():
		_set_output(result, false)
	else:
		_set_output("OK: %s" % trimmed, false)

func _set_output(msg: String, is_error: bool) -> void:
	_output.text = msg
	_output.modulate = Color.TOMATO if is_error else Color.WHITE
