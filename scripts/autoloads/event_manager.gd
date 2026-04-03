extends Node

const EVENT_DIR = "res://resources/events/concrete/"
const MIN_EVENT_INTERVAL := 20
const MAX_EVENT_INTERVAL := 40

var _event_pool: Array = []
var _active_modifiers: Array[Dictionary] = []
var _ticks_until_next_event: int = 0
var _pending_event = null  # EventDef awaiting player resolution

func _ready():
	EventBus.tick_processed.connect(_on_tick)
	EventBus.prestige_completed.connect(_on_prestige_completed)
	_load_events()
	_schedule_next_event()

func _on_prestige_completed():
	_active_modifiers.clear()
	_pending_event = null
	_schedule_next_event()

func _load_events():
	var dir = DirAccess.open(EVENT_DIR)
	if not dir:
		push_error("EventManager: could not open %s" % EVENT_DIR)
		return
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := EVENT_DIR + filename
			var res := ResourceLoader.load(path, "EventDef")
			if res is EventDef:
				_event_pool.append(res)
			else:
				push_warning("EventManager: skipping %s, not an EventDef" % path)
		filename = dir.get_next()
	dir.list_dir_end()
	print("EventManager: loaded %d events" % _event_pool.size())

func _on_tick(_tick: Dictionary):
	_tick_down_modifiers()
	if _pending_event != null:
		return
	_ticks_until_next_event -= 1
	if _ticks_until_next_event <= 0:
		_trigger_random_event()

func _tick_down_modifiers():
	var expired: Array[Dictionary] = []
	for mod in _active_modifiers:
		if mod["ticks_remaining"] == -1:
			continue
		mod["ticks_remaining"] -= 1
		if mod["ticks_remaining"] <= 0:
			expired.append(mod)
	for mod in expired:
		_active_modifiers.erase(mod)

func _trigger_random_event():
	if _event_pool.is_empty():
		_schedule_next_event()
		return
	var event: EventDef = _event_pool[randi() % _event_pool.size()]
	_pending_event = event
	EventBus.event_triggered.emit(event)

func resolve(event: EventDef, choice_index: int):
	if choice_index < 0 or choice_index >= event.choices.size():
		return
	var choice: EventChoice = event.choices[choice_index]
	if not choice.effects.is_empty():
		_active_modifiers.append({
			"effects": choice.effects,
			"ticks_remaining": choice.duration_ticks
		})
	_pending_event = null
	EventBus.event_resolved.emit(choice)
	_schedule_next_event()

func apply_active_effects(context: TickContext):
	for mod in _active_modifiers:
		for effect in mod["effects"]:
			effect.apply(context)

func _schedule_next_event():
	_ticks_until_next_event = randi_range(MIN_EVENT_INTERVAL, MAX_EVENT_INTERVAL)
