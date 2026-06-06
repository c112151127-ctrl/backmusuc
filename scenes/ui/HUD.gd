extends CanvasLayer

var stats_label: Label
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var notice_label: Label
var notice_timer: Timer

func _ready() -> void:
	_build_hud()
	GameState.stats_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_inventory)
	GameState.notification_requested.connect(_show_notice)
	_refresh()
	_refresh_inventory()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		inventory_panel.visible = not inventory_panel.visible

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(16, 16)
	top_bar.custom_minimum_size = Vector2(620, 74)
	root.add_child(top_bar)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(stats_label)

	notice_label = Label.new()
	notice_label.position = Vector2(16, 96)
	notice_label.add_theme_font_size_override("font_size", 18)
	notice_label.visible = false
	root.add_child(notice_label)

	notice_timer = Timer.new()
	notice_timer.one_shot = true
	notice_timer.timeout.connect(func() -> void: notice_label.visible = false)
	add_child(notice_timer)

	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(16, 128)
	inventory_panel.custom_minimum_size = Vector2(360, 430)
	inventory_panel.visible = false
	root.add_child(inventory_panel)

	inventory_list = VBoxContainer.new()
	inventory_panel.add_child(inventory_list)

	var touch_box := HBoxContainer.new()
	touch_box.position = Vector2(840, 610)
	touch_box.add_theme_constant_override("separation", 8)
	root.add_child(touch_box)
	_add_touch_button(touch_box, "近戰", "attack_melee")
	_add_touch_button(touch_box, "射擊", "attack_ranged")
	_add_touch_button(touch_box, "互動", "interact")
	_add_touch_button(touch_box, "背包", "open_inventory")
	_add_touch_button(touch_box, "存檔", "save_game")

func _add_touch_button(parent: Control, label: String, action: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(72, 48)
	button.pressed.connect(_pulse_action.bind(action))
	parent.add_child(button)

func _pulse_action(action: String) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.08).timeout
	Input.action_release(action)

func _refresh() -> void:
	stats_label.text = "HP %d/%d   EP %d/%d   彈藥 %d   廢鐵 %d   核心 %d   場景 %s" % [
		GameState.hp,
		GameState.MAX_HP,
		GameState.ep,
		GameState.MAX_EP,
		GameState.ammo,
		GameState.scrap,
		GameState.cores,
		GameState.current_scene_id
	]

func _refresh_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "背包 / 裝備  (I 開關)"
	title.add_theme_font_size_override("font_size", 18)
	inventory_list.add_child(title)
	var equipped := Label.new()
	equipped.text = "裝備: %s" % JSON.stringify(GameState.equipment)
	equipped.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_list.add_child(equipped)
	for item_id in GameState.inventory.keys():
		var amount := int(GameState.inventory[item_id])
		var row := Button.new()
		row.text = "%s x%d" % [_display_name(String(item_id)), amount]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.pressed.connect(_equip_from_inventory.bind(String(item_id)))
		inventory_list.add_child(row)

func _equip_from_inventory(item_id: String) -> void:
	if DataRegistry.get_equipment(item_id).size() > 0:
		GameState.equip_item(item_id)

func _display_name(item_id: String) -> String:
	if DataRegistry.get_equipment(item_id).size() > 0:
		return String(DataRegistry.get_equipment(item_id).get("name", item_id))
	if DataRegistry.get_resource(item_id).size() > 0:
		return String(DataRegistry.get_resource(item_id).get("name", item_id))
	return item_id

func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_label.visible = true
	notice_timer.start(2.2)
