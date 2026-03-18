extends Node

var _upgrades: Dictionary = {}
var _products: Dictionary = {}
var _dependents: Dictionary = {}

const UPGRADE_DIR = "res://resources/upgrades/concrete/"
const PRODUCT_DIR = "res://resources/products/concrete/"

func _ready():
	_load_all()
	_load_all_products()
	
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
				push_warning("UpgradeRegistry: skipping %s, not an ProductDefinition" % path)
		filename = dir.get_next()
	dir.list_dir_end()
	
	_build_independent_index()
	print("Upgrade registry: loaded %d products" % _products.size())
	
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
