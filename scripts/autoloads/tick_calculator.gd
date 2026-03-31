class_name TickCalculator

static func calculate() -> float:
	var context = TickContext.new()
	context.owned_upgrades = GameState.owned_upgrades
	
	for upgrade in GameState.owned_upgrades:
		var def: UpgradeDef = UpgradeRegistry._upgrades[upgrade]
		for effect in def.effects:
			effect.apply(context)
	return compute_income(context)
	
static func compute_income(context: TickContext):
	var income := 0.0
	for store in GameState.current_shops_count:
		for product in GameState.owned_products:
			var def: ProductDefinition = UpgradeRegistry._products[product]
			var product_income = def.margin
			for tag in def.tags:
				if context.margins.has(tag):
					product_income *= context.margins[tag] if context.margins[tag] >= 1 else 1
			income += product_income
	return income
