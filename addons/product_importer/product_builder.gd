@tool
extends EditorScript
class_name ProductBuilder

const OUTPUT_DIR := "res://resources/products/concrete/"
const INPUT_JSON := "res://resources/products/product_data.json"

func run() -> void:
	# Ensure output directory exists
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	# Load and parse JSON
	var file := FileAccess.open(INPUT_JSON, FileAccess.READ)
	if not file:
		push_error("ProductImporter: could not open %s" % INPUT_JSON)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("ProductImporter: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	var data: Array = json.data
	var created := 0
	var updated := 0

	for entry: Dictionary in data:
		var res_path: String = OUTPUT_DIR + entry["id"] + ".tres"
		var product: ProductDefinition

		if ResourceLoader.exists(res_path):
			product = ResourceLoader.load(res_path, "ProductDef", ResourceLoader.CACHE_MODE_IGNORE)
			updated += 1
		else:
			product = ProductDefinition.new()
			created += 1

		# Apply all fields
		product.id           = entry.get("id", "")
		product.display_name = entry.get("display_name", "")
		product.base_price   = float(entry.get("base_price", 0))
		product.tags         = Array(entry.get("tags", []), TYPE_STRING, "", null)

		var save_err := ResourceSaver.save(product, res_path)
		if save_err != OK:
			push_error("ProductImporter: failed to save %s (error %d)" % [res_path, save_err])
		else:
			print("ProductImporter: saved %s" % res_path)

	print("ProductImporter: done — %d created, %d updated." % [created, updated])
