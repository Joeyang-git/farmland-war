class_name chicken
extends building

## 地图引用，由外部（Map）在实例化建筑时赋值
var map: TileMapLayer = null


func _ready() -> void:
	building_name = "鸡"
	size = building_const.SIZE.SMALL
	max_hp = 2
	skill_type = building_const.SKILL_TYPE.ACTIVE
	skill_cd = 5.0
	super()
	call_deferred("_bind_map")


func _bind_map() -> void:
	map = get_tree().get_first_node_in_group("map_layer") as TileMapLayer

func _process(delta: float) -> void:
	super(delta)


## 啄击：CD 就绪后自动选一块相邻非己方格扣 1 血，血量归零则划归己方
func _use_skill() -> void:
	print("chicken _use_skill: owner_uid=%d, map=%s" % [owner_uid, map])
	if map == null:
		return
	var target := _pick_target()
	print("chicken _use_skill: target=%s" % [target])
	if target == Vector2i(-1, -1):
		return
	map.attack_cell(target, owner_uid)


## 从与建筑相邻的非己方格中随机选一个（优先级：距离最近即 4-邻接，随机打乱后选第一个有效的）
func _pick_target() -> Vector2i:
	var neighbors: Array[Vector2i] = [
		origin_cell + Vector2i(0, -1),
		origin_cell + Vector2i(0, 1),
		origin_cell + Vector2i(-1, 0),
		origin_cell + Vector2i(1, 0),
	]
	# 过滤出可攻击的格
	var candidates: Array[Vector2i] = []
	for cell in neighbors:
		if map.is_attackable(cell, owner_uid):
			candidates.append(cell)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	# 随机选一个
	candidates.shuffle()
	return candidates[0]
