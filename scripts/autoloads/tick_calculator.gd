class_name TickCalculator

static func calculate() -> Dictionary:
	var total_income := 0.0
	var total_rep_gain := 0.0

	for store_idx in range(GameState.owned_stores.size()):
		var store: Dictionary = GameState.owned_stores[store_idx]
		var location: LocationDef = UpgradeRegistry._locations.get(store.location_id)
		if not location:
			push_warning("TickCalculator: unknown location_id '%s', skipping store" % store.location_id)
			continue

		var context := TickContext.new()
		context.owned_upgrades = GameState.owned_upgrades
		context.shelf_organization = location.base_shelf_organization

		# apply legacy bonuses (persist across runs)
		for bonus in UpgradeRegistry._legacy_bonuses.values():
			if GameState.legacy_points >= bonus.required_legacy_points:
				for effect in bonus.effects:
					effect.apply(context)

		# apply brand identity passive effects first
		if GameState.brand_identity_id != "":
			var brand: BrandIdentityDef = UpgradeRegistry._brands.get(GameState.brand_identity_id)
			if brand:
				for effect in brand.passive_effects:
					effect.apply(context)

		# apply staff trait effects for this store
		for staff in GameState.hired_staff:
			if staff["assigned_store_idx"] != store_idx:
				continue
			for trait_id in staff["traits"]:
				var trait_def: StaffDef = UpgradeRegistry._staff_traits.get(trait_id)
				if trait_def:
					for effect in trait_def.effects:
						effect.apply(context)

		# apply active event modifiers
		EventManager.apply_active_effects(context)

		# then apply upgrade effects on top
		for upgrade_id in GameState.owned_upgrades:
			var def: UpgradeDef = UpgradeRegistry._upgrades[upgrade_id]
			for effect in def.effects:
				effect.apply(context)

		for archetype_id in location.archetype_distribution:
			var weight: float = location.archetype_distribution[archetype_id]
			var archetype: CustomerArchetype = UpgradeRegistry._archetypes.get(archetype_id)
			if not archetype:
				push_warning("TickCalculator: unknown archetype_id '%s', skipping" % archetype_id)
				continue

			var traffic: float = archetype.visit_frequency * weight * store.local_reputation * context.traffic_multiplier

			for product_id in GameState.owned_products:
				var product: ProductDefinition = UpgradeRegistry._products[product_id]
				var has_affinity := false
				for tag in product.tags:
					if archetype.product_affinities.has(tag):
						has_affinity = true
						break
				if not has_affinity:
					continue

				var upgrade_level: int = GameState.product_upgrades.get(product_id, 0)
				var rev := product.base_price * (1.0 + upgrade_level * 0.2)
				rev *= (1.0 - archetype.price_sensitivity * context.price_modifier)
				rev *= traffic
				rev *= context.shelf_organization
				for tag in product.tags:
					if context.margins.has(tag):
						rev *= context.margins[tag]
				total_income += rev

			total_rep_gain += archetype.loyalty_weight * weight * traffic * context.cleanliness

	return {"income": total_income, "reputation_gain": total_rep_gain}
