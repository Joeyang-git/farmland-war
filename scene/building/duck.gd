## 鸭：被动产钱建筑（PRD 3.4.1）。
## 每隔 skill_cd 秒自动为归属玩家产出少量金币；被摧毁后立即停止产钱（PRD 3.5.1）。
class_name duck
extends building

## 每次产钱数额
const GOLD_PER_TICK: int = 5


func _ready() -> void:
	building_name = "鸭"
	size = building_const.SIZE.SMALL
	max_hp = 2
	cost = building_const.COST_SMALL
	skill_type = building_const.SKILL_TYPE.PASSIVE
	skill_cd = 3.0
	super()


func _process(delta: float) -> void:
	super(delta)


## 基础产钱：每周期向归属玩家的 gold 累加固定金额
func _use_skill() -> void:
	if map == null:
		return
	var p: player = map.players.get(owner_uid) as player
	if p == null:
		return
	p.gold += GOLD_PER_TICK
