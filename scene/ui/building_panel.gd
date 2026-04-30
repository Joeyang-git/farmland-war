## 建筑列表面板，挂载于 UILayer（CanvasLayer）上。
## 在运行时用代码构建所有 UI 元素，不依赖单独的 .tscn。
extends CanvasLayer

## 可建造建筑配置表；cost 对应一次性建造费用（PRD 3.3.1 / 3.5）。
## GDScript const 不支持跨类常量引用，故声明为 var；费用数值与 building_const.COST_* 保持一致。
var BUILDINGS: Array[Dictionary] = [
	{
		"label":   "Home",
		"scene":   "res://scene/building/home.tscn",
		"size":    2,
		"cost":    100,
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(416, 0, 48, 48),
	},
	{
		"label":   "Chicken",
		"scene":   "res://scene/building/chicken.tscn",
		"size":    1,
		"cost":    20,  ## building_const.COST_SMALL
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(464, 272, 16, 16),
	},
	{
		"label":   "Duck",
		"scene":   "res://scene/building/duck.tscn",
		"size":    1,
		"cost":    20,  ## building_const.COST_SMALL
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(480, 272, 16, 16),
	},
	{
		"label":   "Goose",
		"scene":   "res://scene/building/goose.tscn",
		"size":    1,
		"cost":    20,  ## building_const.COST_SMALL
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(128, 48, 16, 16),
	},
	{
		"label":   "Bull",
		"scene":   "res://scene/building/bull.tscn",
		"size":    2,
		"cost":    60,  ## building_const.COST_MEDIUM
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(256, 48, 48, 48),
	},
	{
		"label":   "Pig",
		"scene":   "res://scene/building/pig.tscn",
		"size":    2,
		"cost":    60,  ## building_const.COST_MEDIUM
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(304, 304, 48, 48),
	},
]

## 类型在 LSP 完成索引前暂用 Node，运行时仍为 game 实例
var _game: Node = null
var _gold_label: Label = null
## 各建筑按钮及其费用，用于每帧刷新可用状态
var _buttons: Array[Dictionary] = []  # [{btn, cost}]


func _ready() -> void:
	_game = get_tree().get_first_node_in_group("game_root")
	if _game == null:
		push_error("BuildingPanel: 找不到 game_root 组节点")
		return
	_game.building_placed.connect(_on_building_placed)
	_build_ui()


func _process(_delta: float) -> void:
	_refresh_gold_ui()


func _build_ui() -> void:
	# 金币显示：[图标] [数字]，右上角
	var gold_row := HBoxContainer.new()
	gold_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gold_row.offset_left   = -120.0
	gold_row.offset_top    =   8.0
	gold_row.offset_right  =  -8.0
	gold_row.offset_bottom =  32.0
	gold_row.alignment = BoxContainer.ALIGNMENT_END
	gold_row.add_theme_constant_override("separation", 4)
	add_child(gold_row)

	var coin_icon := TextureRect.new()
	coin_icon.texture                = load("res://assets/imgs/GoldCoin.png")
	coin_icon.expand_mode            = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode           = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.custom_minimum_size    = Vector2(20, 20)
	coin_icon.size_flags_vertical    = Control.SIZE_SHRINK_CENTER
	gold_row.add_child(coin_icon)

	_gold_label = Label.new()
	_gold_label.text = "---"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_gold_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	_gold_label.add_theme_constant_override("outline_size", 2)
	gold_row.add_child(_gold_label)

	# 建筑按钮面板：贴底部、随内容向上扩展高度（按钮多了自动换行）
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top    = 0.0
	panel.offset_bottom = 0.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)

	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	panel.add_child(flow)

	for cfg: Dictionary in BUILDINGS:
		var btn := _make_item(cfg)
		flow.add_child(btn)
		_buttons.append({"btn": btn, "cost": cfg["cost"] as int})


## 单个建筑按钮：上方贴图标，下方挂「名称 价格」标签；尺寸紧凑可换行
func _make_item(cfg: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 44)
	btn.tooltip_text        = "%s（%d金）" % [cfg["label"], cfg["cost"]]

	# 内容容器：填满按钮、不挡输入
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  2
	vbox.offset_top    =  2
	vbox.offset_right  = -2
	vbox.offset_bottom = -2
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# 图标
	var atlas := AtlasTexture.new()
	atlas.atlas  = load(cfg["texture"]) as Texture2D
	atlas.region = cfg["region"] as Rect2

	var icon_rect := TextureRect.new()
	icon_rect.texture            = atlas
	icon_rect.expand_mode        = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode       = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(22, 22)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter       = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_rect)

	# 名称 + 价格（一行展示，字号小）
	var lbl := Label.new()
	lbl.text = "%s %d" % [cfg["label"], cfg["cost"]]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)

	var scene_path: String = cfg["scene"]
	var size:       int    = cfg["size"]
	var cost:       int    = cfg["cost"]

	# 用 gui_input 而非 button_down：鼠标可以拖出按钮再松手而不让按钮状态卡死
	btn.gui_input.connect(func(ev: InputEvent) -> void:
		if btn.disabled:
			return
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				btn.button_pressed = false
				btn.release_focus()
				btn.accept_event()
				var packed := load(scene_path) as PackedScene
				_game.start_drag(packed, size, cost, btn)
	)
	return btn


## 每帧刷新金币文本与按钮可用状态
func _refresh_gold_ui() -> void:
	if _game == null:
		return
	var p: player = _game.get_local_player()
	if p == null:
		return
	var gold: int = p.gold
	_gold_label.text = "%d" % gold
	for entry: Dictionary in _buttons:
		var btn := entry["btn"] as Button
		var cost := entry["cost"] as int
		btn.disabled = (cost > 0 and gold < cost)
		# modulate 会向子节点传递，禁用时图标和文字一起变暗
		btn.modulate.a = 0.5 if btn.disabled else 1.0


func _on_building_placed(_item: Node) -> void:
	pass
