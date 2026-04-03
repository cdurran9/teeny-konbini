extends Node

@export var tick_time := 1.0

var timer: Timer

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = tick_time
	timer.autostart = false
	timer.timeout.connect(_do_tick)
	EventBus.brand_chosen.connect(_on_brand_chosen)
	EventBus.prestige_completed.connect(_on_prestige_completed)

func _on_brand_chosen(_brand_id: String):
	timer.start()

func _on_prestige_completed():
	timer.stop()

func _simulate(num_ticks: int):
	for i in num_ticks:
		_do_tick()

func _do_tick():
	var tick: Dictionary = TickCalculator.calculate()
	EventBus.tick_processed.emit(tick)
