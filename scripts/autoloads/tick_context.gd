class_name TickContext

var margins: Dictionary = {}
var purchase_rates: Dictionary = {}
var owned_upgrades: Array[String] = []

func multiply_margin(category: String, factor: float):
	margins[category] = margins.get(category) + factor
	
func boost_purchase_rate(category: String, factor: float):
	purchase_rates[category] = purchase_rates.get(category) + factor
