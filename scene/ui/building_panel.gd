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
		"region":	Rect2(480, 272, 16, 16),
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
	# 金币显示标签
	_gold_label = Label.new()
	_gold_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gold_label.offset_left   = -120.0
	_gold_label.offset_top    =   8.0
	_gold_label.offset_right  =  -8.0
	_gold_label.offset_bottom =  28.0
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.text = "金币: ---"
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	add_child(_gold_label)

	# 建筑按钮面板
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top    = -52.0
	panel.offset_bottom = 0.0
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	for cfg: Dictionary in BUILDINGS:
		var btn := _make_item(cfg)
		hbox.add_child(btn)
		_buttons.append({"btn": btn, "cost": cfg["cost"] as int})


func _make_item(cfg: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(44, 44)
	btn.tooltip_text        = "%s（%d金）" % [cfg["label"], cfg["cost"]]
	btn.expand_icon         = true

	var atlas    := AtlasTexture.new()
	atlas.atlas  = load(cfg["texture"]) as Texture2D
	atlas.region = cfg["region"] as Rect2
	btn.icon     = atlas

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
	_gold_label.text = "金币: %d" % gold
	for entry: Dictionary in _buttons:
		var btn := entry["btn"] as Button
		var cost := entry["cost"] as int
		btn.disabled = (cost > 0 and gold < cost)


func _on_building_placed(_item: Node) -> void:
	pass
