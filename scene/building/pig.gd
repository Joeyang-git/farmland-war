## 猪：被动产钱建筑·超高产（PRD 3.4.1 中级）。
## 每隔 skill_cd 秒为归属玩家产出大量金币，被摧毁后立即停止产钱（PRD 3.5.1）。
class_name pig
extends building

## 每次产钱数额（猪是中级产钱，远高于鸭的基础产钱）
const GOLD_PER_TICK: int = 25


func _ready() -> void:
	building_name = "猪"
	size = building_const.SIZE.MEDIUM
	max_hp = 16
	cost = building_const.COST_MEDIUM
	skill_type = building_const.SKILL_TYPE.PASSIVE
	skill_cd = 5.0
	super()


func _process(delta: float) -> void:
	super(delta)


## 超高产：每周期向归属玩家的 gold 累加大额金币
func _use_skill() -> void:
	if map == null:
		return
	var p: player = map.players.get(owner_uid) as player
	if p == null:
		return
	p.gold += GOLD_PER_TICK
