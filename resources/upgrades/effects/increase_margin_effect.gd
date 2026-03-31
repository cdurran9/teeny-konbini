extends Effect
class_name IncreaseMarginEffect

@export var product_tags: Dictionary[String, float] = {}

func apply(context: TickContext):
	for tag in product_tags:
		context.multiply_margin(tag, product_tags.get(tag))
