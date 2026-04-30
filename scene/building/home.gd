class_name home
extends building


func _ready() -> void:
	building_name = "Home"
	size = building_const.SIZE.MEDIUM
	cost = building_const.COST_MEDIUM
	max_hp = 32
	super()
