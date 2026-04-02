extends Node

var _upgrades: Dictionary = {}
var _products: Dictionary = {}
var _archetypes: Dictionary = {}
var _locations: Dictionary = {}
var _brands: Dictionary = {}
var _dependents: Dictionary = {}

const UPGRADE_DIR = "res://resources/upgrades/concrete/"
const PRODUCT_DIR = "res://resources/products/concrete/"
const ARCHETYPE_DIR = "res://resources/customers/concrete/"
const LOCATION_DIR = "res://resources/locations/concrete/"
const BRAND_DIR = "res://resources/brand/concrete/"

func _ready():
	_load_all()
	_load_all_products()
	_load_all_archetypes()
	_load_all_locations()
	_load_all_brands()

func _load_all():
	var dir = DirAccess.open(UPGRADE_DIR)
	if not dir:
		push_error("Upgrade registry: could not load %s" % UPGRADE_DIR)
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := UPGRADE_DIR + filename
			var res := ResourceLoader.load(path, "UpgradeDef")
			if res is UpgradeDef:
				if _upgrades.has(res.id):
					push_warning("Upgrade registry: duplicate ID found (%s)" % res.id)
				else:
					_upgrades[res.id] = res
			else:
				push_warning("UpgradeRegistry: skipping %s, not an UpgradeDef" % path)
		filename = dir.get_next()
	dir.list_dir_end()

	_build_independent_index()
	print("Upgrade registry: loaded %d upgrades" % _upgrades.size())

func _load_all_products():
	var dir = DirAccess.open(PRODUCT_DIR)
	if not dir:
		push_error("Upgrade registry: could not load %s" % PRODUCT_DIR)
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := PRODUCT_DIR + filename
			var res := ResourceLoader.load(path, "ProductDefinition")
			if res is ProductDefinition:
				if _products.has(res.id):
					push_warning("Upgrade registry: duplicate ID found (%s)" % res.id)
				else:
					_products[res.id] = res
			else:
				push_warning("UpgradeRegistry: skipping %s, not a ProductDefinition" % path)
		filename = dir.get_next()
	dir.list_dir_end()
	print("Upgrade registry: loaded %d products" % _products.size())

func _load_all_archetypes():
	var dir = DirAccess.open(ARCHETYPE_DIR)
	if not dir:
		push_error("Upgrade registry: could not load %s" % ARCHETYPE_DIR)
		return
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := ARCHETYPE_DIR + filename
			var res := ResourceLoader.load(path, "CustomerArchetype")
			if res is CustomerArchetype:
				if _archetypes.has(res.id):
					push_warning("Upgrade registry: duplicate archetype ID found (%s)" % res.id)
				else:
					_archetypes[res.id] = res
			else:
				push_warning("UpgradeRegistry: skipping %s, not a CustomerArchetype" % path)
		filename = dir.get_next()
	dir.list_dir_end()
	print("Upgrade registry: loaded %d archetypes" % _archetypes.size())

func _load_all_locations():
	var dir = DirAccess.open(LOCATION_DIR)
	if not dir:
		push_error("Upgrade registry: could not load %s" % LOCATION_DIR)
		return
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := LOCATION_DIR + filename
			var res := ResourceLoader.load(path, "LocationDef")
			if res is LocationDef:
				if _locations.has(res.id):
					push_warning("Upgrade registry: duplicate location ID found (%s)" % res.id)
				else:
					_locations[res.id] = res
			else:
				push_warning("UpgradeRegistry: skipping %s, not a LocationDef" % path)
		filename = dir.get_next()
	dir.list_dir_end()
	print("Upgrade registry: loaded %d locations" % _locations.size())

func _load_all_brands():
	var dir = DirAccess.open(BRAND_DIR)
	if not dir:
		push_error("Upgrade registry: could not load %s" % BRAND_DIR)
		return
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := BRAND_DIR + filename
			var res := ResourceLoader.load(path, "BrandIdentityDef")
			if res is BrandIdentityDef:
				if _brands.has(res.id):
					push_warning("Upgrade registry: duplicate brand ID found (%s)" % res.id)
				else:
					_brands[res.id] = res
			else:
				push_warning("UpgradeRegistry: skipping %s, not a BrandIdentityDef" % path)
		filename = dir.get_next()
	dir.list_dir_end()
	print("Upgrade registry: loaded %d brands" % _brands.size())

func _build_independent_index():
	for id in _upgrades:
		_dependents[id] = []
	for id in _upgrades:
		var def: UpgradeDef = _upgrades[id]
		for prereq_id in def.prerequisites:
			if not _upgrades.has(prereq_id):
				push_error("Upgrade registry: %s requires unknown prerequisite '%s'" % [def.id, prereq_id])
				continue
			_dependents[prereq_id].append(id)
