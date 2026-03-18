extends Effect
class_name IncreasePurchaseRateEffect

@export var product_tags: Dictionary[String, float] = {}

func apply(context: TickContext):
	for tag in product_tags:
		context.boost_purchase_rate(tag, product_tags.get(tag))
