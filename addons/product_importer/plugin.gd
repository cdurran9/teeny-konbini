@tool
extends EditorPlugin

var _menu: MenuButton

func _enter_tree() -> void:
	_menu = MenuButton.new()
	_menu.text = "Tools"
	_menu.get_popup().add_item("Import Products", 0)
	_menu.get_popup().add_item("Import Upgrades", 1)  # easy to extend
	_menu.get_popup().id_pressed.connect(_on_menu_item_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _menu)

func _exit_tree() -> void:
	if _menu:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _menu)
		_menu.queue_free()

func _on_menu_item_pressed(id: int) -> void:
	match id:
		0: ProductBuilder.new().run()
		1: pass # UpgradeImporter etc.
