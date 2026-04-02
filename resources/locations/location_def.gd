extends Resource
class_name LocationDef

@export var id: String
@export var display_name: String
# archetype_id → weight (weights should sum to 1.0)
@export var archetype_distribution: Dictionary[String, float] = {}
@export var base_shelf_organization: float = 1.0
@export var base_dwell_modifier: float = 1.0
@export var reputation_requirement: float = 0.0
