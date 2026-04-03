extends Node

signal tick_processed(tick_data: Dictionary)
signal money_changed(new_value: float)
signal upgrade_purchased(upgrade: String)
signal reputation_changed(new_value: float)
signal store_opened(location_id: String)
signal brand_chosen(brand_id: String)
signal staff_hired(staff_data: Dictionary)
signal staff_quit(staff_data: Dictionary)
signal research_completed(choices: Array)
signal event_triggered(event_def)
signal event_resolved(choice)
