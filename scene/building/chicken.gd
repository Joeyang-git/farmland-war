class_name chicken
extends building


func _ready() -> void:
	building_name = "鸡"
	size = building_const.SIZE.SMALL
	max_hp = 2
	cost = building_const.COST_SMALL
	skill_cd = 5.0
	super()


func _process(delta: float) -> void:
	super(delta)


## 啄击：CD 就绪后自动选一块相邻非己方格扣 1 血，血量归零则划归己方
func _use_skill() -> void:
	if map == null:
		return
	var target := _pick_target()
	if target == Vector2i(-1, -1):
		return
	map.attack_cell(target, owner_uid)


## 从该玩家所有地块的边界邻接格中选目标：优先距小鸡最近的格，同距离随机
func _pick_target() -> Vector2i:
	var candidates: Array[Vector2i] = map.get_border_targets(owner_uid)
	if candidates.is_empty():
		return Vector2i(-1, -1)

	# 计算每格到小鸡 origin_cell 的曼哈顿距离，找最小值
	var best_dist: int = 0x7FFFFFFF
	for cell in candidates:
		var d: int = abs(cell.x - origin_cell.x) + abs(cell.y - origin_cell.y)
		if d < best_dist:
			best_dist = d

	# 收集所有最近的格，随机选一个
	var closest: Array[Vector2i] = []
	for cell in candidates:
		if abs(cell.x - origin_cell.x) + abs(cell.y - origin_cell.y) == best_dist:
			closest.append(cell)
	closest.shuffle()
	return closest[0]
