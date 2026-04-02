extends Effect
class_name ModifyContextStatEffect

@export var stat_name: String = ""
@export var multiplier: float = 1.0

func apply(context: TickContext):
	match stat_name:
		"price_modifier":
			context.price_modifier *= multiplier
		"shelf_organization":
			context.shelf_organization *= multiplier
		"cleanliness":
			context.cleanliness *= multiplier
		"traffic_multiplier":
			context.traffic_multiplier *= multiplier
