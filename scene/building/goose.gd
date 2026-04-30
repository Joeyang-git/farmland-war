## 鹅：自动攻击建筑·干扰（PRD 3.4.1 低级）。
## CD 就绪后自动对一座邻接敌方建筑施加干扰（CD 推进 -33%，相当于 CD 延长 50%），持续 5 秒。
class_name goose
extends building

## 干扰持续时间（秒）
const DISTURB_DURATION: float = 5.0


func _ready() -> void:
	building_name = "鹅"
	size = building_const.SIZE.SMALL
	max_hp = 2
	cost = building_const.COST_SMALL
	skill_cd = 10.0
	super()


func _process(delta: float) -> void:
	super(delta)


## 干扰：找一座邻接敌方建筑，对其调用 [method building.apply_disturb]
func _use_skill() -> void:
	if map == null:
		return
	var target: building = _pick_target()
	if target == null:
		return
	target.apply_disturb(DISTURB_DURATION)


## 在 4 个邻接格中收集所有不同的敌方建筑，随机挑一个；没有则返回 null
func _pick_target() -> building:
	var dirs := [
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(1, 0),
	]
	var seen: Dictionary = {}
	var candidates: Array[building] = []
	for d in dirs:
		var nb: Vector2i = origin_cell + d
		var b: building = map.occupied_cells.get(nb) as building
		if b == null:
			continue
		if b.owner_uid == owner_uid:
			continue
		if seen.has(b):
			continue
		seen[b] = true
		candidates.append(b)
	if candidates.is_empty():
		return null
	candidates.shuffle()
	return candidates[0]
