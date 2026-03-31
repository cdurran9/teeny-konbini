extends Effect
class_name UnlockProductEffect

@export var products: Array[String] = []

func on_purchase():
	for product in products:
		GameState.purchase_product(product)
