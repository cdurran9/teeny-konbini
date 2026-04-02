extends Effect
class_name OpenStoreEffect

@export var location_id: String = ""

func on_purchase():
	GameState.open_store(location_id)
