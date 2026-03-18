extends Control
@onready var label = $Label
@onready var button_candy = $Button_Candy
@onready var button_soda = $Button_Soda

func _ready():
	EventBus.money_changed.connect(update_score)
	button_candy.pressed.connect(func(): on_click('candy'))
	button_soda.pressed.connect(func(): on_click('soda'))

func update_score(new_score: int):
	label.text = str(new_score)
	
func on_click(sig):
	print(sig)
	GameState.purchase_product(sig)
