## 牛：自动攻击建筑·践踏（PRD 3.4.1 中级）。
## CD 就绪后基于「己方领土边界邻接格」挑出一个 2×2 区域，对其每格造成 1 点伤害；
## 目标格血量归零则按 [method farm_map.attack_cell] 的规则归属己方（建筑命中走 [method building.take_damage]）。
##
## 选位策略（与 [class chicken] 一致基于领土边界，而非牛自身邻接）：
##   1. 取 [method farm_map.get_border_targets]：所有「与己方领地相邻的可攻击格」
##   2. 把每个边界格当作 2×2 块的某个角，枚举出所有候选 2×2 块（去重）
##   3. 计分：块内可攻击格数量越多分越高
##   4. 同分时优先距离牛更近的块；仍同分则随机选一块（与 chicken 同手感）
class_name bull
extends building

## 单格伤害（每格扣 1 点耐久，由 attack_cell 处理占领判定）
const DAMAGE_PER_CELL: int = 1


func _ready() -> void:
	building_name = "牛"
	size = building_const.SIZE.MEDIUM
	max_hp = 12
	cost = building_const.COST_MEDIUM
	skill_cd = 15.0
	super()


func _process(delta: float) -> void:
	super(delta)


## 践踏：选出最佳 2×2 块，对其每格造成 1 点伤害；无任何边界目标则不释放
func _use_skill() -> void:
	if map == null:
		return
	var target_cells: Array[Vector2i] = _pick_best_quadrant()
	if target_cells.is_empty():
		return
	for cell in target_cells:
		for _i in range(DAMAGE_PER_CELL):
			map.attack_cell(cell, owner_uid)


## 在所有「邻接己方领土的可攻击格」周围枚举 2×2 候选块；
## 按 (-可攻击格数, 距牛曼哈顿距离) 排序，挑最佳；同分随机。
func _pick_best_quadrant() -> Array[Vector2i]:
	var border: Array[Vector2i] = map.get_border_targets(owner_uid)
	if border.is_empty():
		return []

	# 一个边界格 c 可能位于 2×2 块的 4 个角；origin = c + offset
	var corner_offsets := [
		Vector2i( 0,  0),  # c 在左上
		Vector2i(-1,  0),  # c 在右上
		Vector2i( 0, -1),  # c 在左下
		Vector2i(-1, -1),  # c 在右下
	]

	var seen: Dictionary = {}
	var best_score: int = 0
	var best_dist: int = 0x7FFFFFFF
	var best_blocks: Array[Array] = []

	for c in border:
		for off in corner_offsets:
			var origin: Vector2i = c + off
			if seen.has(origin):
				continue
			seen[origin] = true

			var block: Array[Vector2i] = [
				origin,
				origin + Vector2i(1, 0),
				origin + Vector2i(0, 1),
				origin + Vector2i(1, 1),
			]

			var score: int = 0
			for cell in block:
				if map.is_attackable(cell, owner_uid):
					score += 1
			if score == 0:
				continue

			# 距牛曼哈顿距离：用块中心和牛中心近似（牛 origin_cell 也是左上角，块同理）
			var dist: int = absi(origin.x - origin_cell.x) + absi(origin.y - origin_cell.y)

			if score > best_score or (score == best_score and dist < best_dist):
				best_score = score
				best_dist = dist
				best_blocks = [block]
			elif score == best_score and dist == best_dist:
				best_blocks.append(block)

	if best_blocks.is_empty():
		return []

	best_blocks.shuffle()
	var result: Array[Vector2i] = []
	for cell in best_blocks[0]:
		result.append(cell as Vector2i)
	return result
