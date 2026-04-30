## 简易 AI 控制器（PRD 4.1.9）。
##
## 行动逻辑：周期性决策，按 PRD「扩张领地→建造产钱建筑→建造战斗建筑」的优先级行动。
##   1. 鸭（早期产钱）数量未达目标且金币足够 → 建鸭（1×1）
##   2. 猪（主力产钱）数量未达目标且金币足够 → 建猪（2×2）
##   3. 牛（主力攻击）数量未达目标且金币足够 → 建牛（2×2）
##   4. 能在贴脸敌方建筑处放下鹅 → 建鹅（1×1，仅在能立刻发挥干扰时建）
##   5. 兜底 → 建鸡（1×1，自动攻击会沿边界扩张领地）
##
## 选位：优先靠近敌方领地的己方空地（曼哈顿距离最小者）；鹅另走「邻接敌方建筑」专用选位。
##
## 挂载方式：由 map.gd 在 _collect_players() 中为 AI 玩家创建 ai_controller 子节点。
class_name ai_controller
extends Node

## 决策周期（秒）
const DECISION_INTERVAL: float = 3.0
## 各类建筑的目标拥有数量
const TARGET_DUCK_COUNT: int = 2
const TARGET_PIG_COUNT:  int = 2
const TARGET_BULL_COUNT: int = 2

## 控制的玩家 uid（与父 player 节点的 uid 一致）
var owner_uid: int = 0

var _map: farm_map = null
var _building_container: Node2D = null
var _timer: float = 0.0

var _chicken_scene: PackedScene = preload("res://scene/building/chicken.tscn")
var _duck_scene:    PackedScene = preload("res://scene/building/duck.tscn")
var _pig_scene:     PackedScene = preload("res://scene/building/pig.tscn")
var _bull_scene:    PackedScene = preload("res://scene/building/bull.tscn")
var _goose_scene:   PackedScene = preload("res://scene/building/goose.tscn")


func _ready() -> void:
	_map = get_tree().get_first_node_in_group("map_layer") as farm_map
	var game_root := get_tree().get_first_node_in_group("game_root")
	if game_root != null:
		_building_container = game_root.get_node_or_null("BuildingContainer") as Node2D


func _process(delta: float) -> void:
	if _map == null or _building_container == null:
		return
	_timer += delta
	if _timer < DECISION_INTERVAL:
		return
	_timer = 0.0
	_decide()


## 决策入口：按 「鸭→猪→牛→鹅→鸡」 的优先级尝试建造，命中即返回
func _decide() -> void:
	var p: player = _map.players.get(owner_uid) as player
	if p == null:
		return

	# 1) 早期产钱：基础鸭群
	if _count_owned("duck") < TARGET_DUCK_COUNT and p.gold >= building_const.COST_SMALL:
		if _try_build(_duck_scene, 1, building_const.COST_SMALL, p):
			return

	# 2) 主力产钱：超高产猪（中级 2×2）
	if _count_owned("pig") < TARGET_PIG_COUNT and p.gold >= building_const.COST_MEDIUM:
		if _try_build(_pig_scene, 2, building_const.COST_MEDIUM, p):
			return

	# 3) 主力攻击：践踏牛（中级 2×2）
	if _count_owned("bull") < TARGET_BULL_COUNT and p.gold >= building_const.COST_MEDIUM:
		if _try_build(_bull_scene, 2, building_const.COST_MEDIUM, p):
			return

	# 4) 战术干扰：只在能贴脸敌方建筑时造鹅，避免无效建造
	if p.gold >= building_const.COST_SMALL:
		var goose_cell: Vector2i = _find_goose_placement()
		if goose_cell != Vector2i.MAX:
			if _try_build_at(_goose_scene, goose_cell, building_const.COST_SMALL, p):
				return

	# 5) 兜底扩张：鸡群沿边界推进
	if p.gold >= building_const.COST_SMALL:
		_try_build(_chicken_scene, 1, building_const.COST_SMALL, p)


## 数本 AI 拥有的指定类型建筑数量
func _count_owned(kind: String) -> int:
	var count: int = 0
	for node in get_tree().get_nodes_in_group("building"):
		var b := node as building
		if b == null or b.owner_uid != owner_uid:
			continue
		if kind == "duck" and b is duck:
			count += 1
		elif kind == "chicken" and b is chicken:
			count += 1
		elif kind == "pig" and b is pig:
			count += 1
		elif kind == "bull" and b is bull:
			count += 1
		elif kind == "goose" and b is goose:
			count += 1
	return count


## 尝试建造：按 size 启发式选位 → 扣金币 → 实例化并注册到 map
func _try_build(scene: PackedScene, size: int, cost: int, p: player) -> bool:
	return _try_build_at(scene, _find_placement(size), cost, p)


## 在指定 cell 直接建造（已校验通过的情况下）；扣金币 → 实例化并注册到 map
func _try_build_at(scene: PackedScene, cell: Vector2i, cost: int, p: player) -> bool:
	if cell == Vector2i.MAX:
		return false
	p.gold -= cost
	var b: building = scene.instantiate() as building
	b.owner_uid = owner_uid
	b.position  = Vector2(cell) * building_const.TILE_SIZE
	_building_container.add_child(b)
	_map.register_building(b)
	return true


## 在己方领地中寻找一个 size×size 都合法的左上角格。
## 启发式：优先选离最近敌格曼哈顿距离最小的位置（更靠近边界、产出/攻击更高效）。
func _find_placement(size: int) -> Vector2i:
	var p: player = _map.players.get(owner_uid) as player
	if p == null:
		return Vector2i.MAX

	var legal: Array[Vector2i] = []
	for cell in p.cells:
		if _map.can_place_building(cell, size, owner_uid):
			legal.append(cell)
	if legal.is_empty():
		return Vector2i.MAX

	var enemy_cells: Array[Vector2i] = _collect_enemy_cells()
	if enemy_cells.is_empty():
		legal.shuffle()
		return legal[0]

	# 选择到最近敌格距离最小的合法位置
	var best: Vector2i = legal[0]
	var best_dist: int = 0x7FFFFFFF
	for cell in legal:
		var d: int = _min_dist_to(cell, enemy_cells)
		if d < best_dist:
			best_dist = d
			best = cell
	return best


## 寻找一个合法的 1×1 位置，且与某个敌方建筑相邻；找不到返回 Vector2i.MAX。
## 鹅只在邻接敌方建筑时才能发挥干扰技能，因此走专用选位逻辑。
func _find_goose_placement() -> Vector2i:
	var p: player = _map.players.get(owner_uid) as player
	if p == null:
		return Vector2i.MAX
	var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for cell in p.cells:
		if not _map.can_place_building(cell, 1, owner_uid):
			continue
		for d in dirs:
			var nb: Vector2i = cell + d
			var b: building = _map.occupied_cells.get(nb) as building
			if b != null and b.owner_uid != owner_uid:
				return cell
	return Vector2i.MAX


## 收集所有非己方玩家的格子
func _collect_enemy_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for uid in _map.players.keys():
		if uid == owner_uid:
			continue
		var enemy: player = _map.players[uid] as player
		for cell in enemy.cells:
			result.append(cell)
	return result


func _min_dist_to(from: Vector2i, targets: Array[Vector2i]) -> int:
	var best: int = 0x7FFFFFFF
	for t in targets:
		var d: int = abs(t.x - from.x) + abs(t.y - from.y)
		if d < best:
			best = d
	return best
