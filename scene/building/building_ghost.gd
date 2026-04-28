## 建筑拖拽时跟随鼠标的半透明预览；由 game.gd 控制显隐与状态。
extends Node2D

const TILE_SIZE := building_const.TILE_SIZE
const COLOR_VALID   := Color(0.2, 1.0, 0.3, 0.45)
const COLOR_INVALID := Color(1.0, 0.2, 0.2, 0.45)
const COLOR_GRID    := Color(1.0, 1.0, 1.0, 0.35)

var _size: int  = 1
var _valid: bool = false


func _ready() -> void:
	hide()
	z_index = 10


## 更新预览状态并刷新绘制。
func set_state(size: int, valid: bool) -> void:
	_size  = size
	_valid = valid
	show()
	queue_redraw()


func _draw() -> void:
	var px := float(_size * TILE_SIZE)
	var fill_color := COLOR_VALID if _valid else COLOR_INVALID
	draw_rect(Rect2(0.0, 0.0, px, px), fill_color)
	for i in range(_size + 1):
		var off := float(i * TILE_SIZE)
		draw_line(Vector2(off, 0.0), Vector2(off, px),   COLOR_GRID, 0.5)
		draw_line(Vector2(0.0, off), Vector2(px,  off),  COLOR_GRID, 0.5)
