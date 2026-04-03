extends Resource
class_name EventChoice

@export var label: String
@export var description: String
@export var effects: Array[Effect]
# duration in ticks; -1 = permanent (never expires)
@export var duration_ticks: int = 5
