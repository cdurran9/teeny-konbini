class_name TickContext

var margins: Dictionary = {}
var purchase_rates: Dictionary = {}
var owned_upgrades: Array[String] = []

func multiply_margin(category: String, factor: float):
	var current_value = margins.get(category) if margins.get(category) != null else 1
	margins[category] = current_value + factor
	
func boost_purchase_rate(category: String, factor: float):
	purchase_rates[category] = purchase_rates.get(category) + factor
