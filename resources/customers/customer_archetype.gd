extends Resource
class_name CustomerArchetype

@export var id: String
@export var display_name: String
@export var dwell_time: float           # future: affects queue capacity
@export var price_sensitivity: float    # 0.0–1.0; higher = more price-averse
@export var product_affinities: Array[String]  # matched against ProductDefinition.tags
@export var loyalty_weight: float       # contribution to brand_reputation per visit
@export var visit_frequency: float      # base visits per tick (scaled by distribution weight)
