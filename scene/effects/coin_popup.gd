## 建筑产钱时弹出的「+N 金币」飘字。
## 上飞 + 淡出，动画完成后自动 [method queue_free]。
##
## 用法：
##     var pop := coin_popup.new()
##     pop.setup(amount)
##     pop.position = ...
##     parent.add_child(pop)
class_name coin_popup
extends Node2D

const RISE_DISTANCE: float = 22.0   ## 上飞像素
const DURATION:      float = 0.9    ## 总动画时长（秒）
const ICON_PX:       float = 12.0   ## 图标显示尺寸（像素）
const FONT_SIZE:     int   = 9
const FADE_DELAY:    float = 0.3    ## 飘到该时刻才开始淡出
const POP_SCALE:     float = 1.25   ## 弹跳到该倍率再落回 1.0

## 用 load() 而非 preload()：避免 Godot 尚未 import .png 时 LSP 报错；
## 实际运行时 .import 已生成，load 走缓存几乎零成本。
const GOLD_COIN_TEX_PATH: String = "res://assets/imgs/GoldCoin.png"

var _amount: int = 0


## 建造方调用：必须在 add_child 之前 setup
func setup(amount: int) -> void:
	_amount = amount


func _ready() -> void:
	z_index = 10  # 飘字盖在建筑上面

	# 金币图标
	var icon := Sprite2D.new()
	var tex := load(GOLD_COIN_TEX_PATH) as Texture2D
	if tex != null:
		icon.texture  = tex
		icon.centered = true
		var tex_size := tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			icon.scale = Vector2(ICON_PX / tex_size.x, ICON_PX / tex_size.y)
	add_child(icon)

	# +N 数字
	var lbl := Label.new()
	lbl.text = "+%d" % _amount
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	lbl.position = Vector2(ICON_PX * 0.5 + 1.0, -FONT_SIZE * 0.7)
	add_child(lbl)

	_play_animation()


func _play_animation() -> void:
	var start_y: float = position.y
	var tween := create_tween().set_parallel(true)
	# 上飞（缓出）
	tween.tween_property(self, "position:y", start_y - RISE_DISTANCE, DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 弹跳放大再回落
	tween.tween_property(self, "scale", Vector2(POP_SCALE, POP_SCALE), DURATION * 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, DURATION * 0.4) \
		.set_delay(DURATION * 0.25)
	# 延迟淡出
	tween.tween_property(self, "modulate:a", 0.0, DURATION - FADE_DELAY) \
		.set_delay(FADE_DELAY)
	tween.chain().tween_callback(queue_free)
