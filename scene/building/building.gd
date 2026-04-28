## 所有动物建筑的基类。子类负责覆写 [method _use_skill] 实现具体技能逻辑。
class_name building
extends Node2D

# ---------------------------------------------------------------------------
# 基础属性（子类可用 @export 覆盖默认值）
# ---------------------------------------------------------------------------
## 建筑名称，用于 UI / 调试
@export var building_name: String = ""
## 占地尺寸（格）
@export var size: building_const.SIZE = building_const.SIZE.SMALL
## 最大耐久（血量）
@export var max_hp: int = 2
## 技能类型
@export var skill_type: building_const.SKILL_TYPE = building_const.SKILL_TYPE.PASSIVE
## 技能冷却时间（秒）；被动类等价为产钱/触发周期
@export var skill_cd: float = 5.0

## 所属玩家 uid（由 Map 在建造时赋值）
@export var owner_uid: int = 0
## 建筑左上角所在格坐标
var origin_cell: Vector2i = Vector2i.ZERO
## 当前耐久
var hp: int = max_hp
## 地图引用，_ready 后自动从 "map_layer" 组获取
var map: TileMapLayer = null

# ---------------------------------------------------------------------------
# 运行时状态（不暴露给编辑器）
# ---------------------------------------------------------------------------
## 封锁状态：true 时 CD 不推进、技能不释放
var is_blocked: bool = false
## CD 计时器（秒）；达到 skill_cd 时触发技能
var _cd_timer: float = 0.0

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------
## 建筑被摧毁时发出
signal destroyed(b: building)
## 技能就绪并选点后发出（主动），或被动触发后发出
signal skill_triggered(b: building)

# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------
func _enter_tree() -> void:
	add_to_group("building")


func _ready() -> void:
	hp = max_hp
	fix_to_grid()
	_fit_sprite()
	call_deferred("_bind_map")


func _bind_map() -> void:
	map = get_tree().get_first_node_in_group("map_layer") as TileMapLayer


func _process(delta: float) -> void:
	if is_blocked:
		return
	_cd_timer += delta
	if _cd_timer >= skill_cd:
		_cd_timer = 0.0
		_on_skill_ready()


# ---------------------------------------------------------------------------
# 内部：技能就绪回调
# ---------------------------------------------------------------------------
func _on_skill_ready() -> void:
	_use_skill()
	skill_triggered.emit(self)


# ---------------------------------------------------------------------------
# 子类覆写：具体技能逻辑
# ---------------------------------------------------------------------------
## 主动技能：由子类实现选点与伤害逻辑；被动技能同样覆写此方法（已保证按周期调用）。
func _use_skill() -> void:
	pass


# ---------------------------------------------------------------------------
# 受击
# ---------------------------------------------------------------------------
## 对建筑造成固定伤害；返回建筑是否已被摧毁。
func take_damage(amount: int) -> bool:
	hp -= amount
	if hp <= 0:
		hp = 0
		_on_destroyed()
		return true
	return false


func _on_destroyed() -> void:
	destroyed.emit(self)
	queue_free()


## 适用于编辑器摆放后校正，或代码设置 position 后同步格坐标。
func fix_to_grid() -> void:
	var ts: float = building_const.TILE_SIZE
	var aligned := Vector2(
		floorf(position.x / ts) * ts,
		floorf(position.y / ts) * ts
	)
	position = aligned
	origin_cell = Vector2i(int(aligned.x / ts), int(aligned.y / ts))

	print("fix_to_grid: position=%s origin_cell=%s" % [position, origin_cell])


## 返回建筑占用的所有格坐标（以 origin_cell 为左上角，按 size 展开）。
func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var s: int = size as int
	for dy in range(s):
		for dx in range(s):
			result.append(origin_cell + Vector2i(dx, dy))
	return result


## 让子节格点 Sprite2D 的缩放与尺寸对齐瓦片。
## Sprite2D 原始贴图若不是标准格尺寸，scale 会自动补偿。
func _fit_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var tex := sprite.texture
	if tex == null:
		return
	var target_px: float = (size as int) * building_const.TILE_SIZE

	sprite.scale = Vector2(target_px / tex.get_width(), target_px / tex.get_height())

	print("fit_sprite: scale=%s tex.width=%s tex.height=%s target_px=%s" % [sprite.scale, tex.get_width(), tex.get_height(), target_px])
