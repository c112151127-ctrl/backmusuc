extends CanvasLayer

const MINIMAP_VIEW := preload("res://scripts/ui/MiniMapView.gd")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

var stats_label: Label
var quest_label: Label
var quick_bar_panel: PanelContainer
var quick_bar: HBoxContainer
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var notice_label: Label
var notice_timer: Timer
var minimap_panel: PanelContainer
var tutorial_panel: PanelContainer
var controls_hint: Label
var dialogue_panel: PanelContainer
var dialogue_speaker: Label
var dialogue_body: Label
var dialogue_timer: Timer

func _ready() -> void:
	_build_hud()
	GameState.stats_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_hotbar)
	GameState.notification_requested.connect(_show_notice)
	GameState.dialogue_requested.connect(_show_dialogue)
	_refresh()
	_refresh_inventory()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		_set_inventory_visible(not inventory_panel.visible)
	if Input.is_action_just_pressed("toggle_minimap"):
		minimap_panel.visible = not minimap_panel.visible
	if Input.is_action_just_pressed("toggle_help"):
		tutorial_panel.visible = not tutorial_panel.visible

func _set_inventory_visible(is_visible: bool) -> void:
	inventory_panel.visible = is_visible
	quick_bar_panel.visible = is_visible

func _build_hud() -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(16, 16)
	top_bar.custom_minimum_size = Vector2(520, 74)
	root.add_child(top_bar)

	var top_stack := VBoxContainer.new()
	top_bar.add_child(top_stack)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 16)
	top_stack.add_child(stats_label)
	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 14)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_stack.add_child(quest_label)

	notice_label = Label.new()
	notice_label.position = Vector2(18, 98)
	notice_label.add_theme_font_size_override("font_size", 15)
	notice_label.visible = false
	root.add_child(notice_label)
	notice_timer = Timer.new()
	notice_timer.one_shot = true
	notice_timer.timeout.connect(func() -> void: notice_label.visible = false)
	add_child(notice_timer)

	_build_inventory_panel(root)
	_add_quick_bar(root)
	_add_minimap(root)
	_add_tutorial(root)
	_add_controls_hint(root)
	_add_dialogue_box(root)

func _build_inventory_panel(root: Control) -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.add_to_group("equipment_panel")
	inventory_panel.position = Vector2(28, 92)
	inventory_panel.custom_minimum_size = Vector2(620, 560)
	inventory_panel.z_index = 40
	inventory_panel.visible = false
	root.add_child(inventory_panel)
	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(inventory_list)

func _add_quick_bar(root: Control) -> void:
	quick_bar_panel = PanelContainer.new()
	quick_bar_panel.name = "QuickBarPanel"
	quick_bar_panel.position = Vector2(470, 646)
	quick_bar_panel.custom_minimum_size = Vector2(388, 58)
	quick_bar_panel.visible = false
	root.add_child(quick_bar_panel)
	quick_bar = HBoxContainer.new()
	quick_bar.name = "QuickBar"
	quick_bar.add_theme_constant_override("separation", 6)
	quick_bar_panel.add_child(quick_bar)

func _add_minimap(root: Control) -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.add_to_group("minimap_panel")
	minimap_panel.position = Vector2(1030, 18)
	minimap_panel.custom_minimum_size = Vector2(220, 154)
	minimap_panel.visible = false
	root.add_child(minimap_panel)
	var map_stack := VBoxContainer.new()
	map_stack.add_theme_constant_override("separation", 4)
	minimap_panel.add_child(map_stack)
	var title := Label.new()
	title.text = "地圖 M"
	title.add_theme_font_size_override("font_size", 15)
	map_stack.add_child(title)
	var map_view: Control = MINIMAP_VIEW.new()
	map_stack.add_child(map_view)

func _add_tutorial(root: Control) -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.add_to_group("tutorial_panel")
	tutorial_panel.position = Vector2(790, 410)
	tutorial_panel.custom_minimum_size = Vector2(430, 198)
	tutorial_panel.visible = false
	root.add_child(tutorial_panel)
	var stack := VBoxContainer.new()
	tutorial_panel.add_child(stack)
	var title := Label.new()
	title.text = "廢土回收商 PC 操作"
	title.add_theme_font_size_override("font_size", 18)
	stack.add_child(title)
	var body := Label.new()
	body.text = "WASD 移動\n滑鼠左鍵：依目前裝備揮砍或射擊\n右鍵 / K：固定射擊\nSpace：固定近戰\nE：互動 / 交談\nTab / I：人物裝備\nQ / 1-4：切換快捷裝備\nM：小地圖\nF5 / F9：存檔 / 讀檔"
	body.add_theme_font_size_override("font_size", 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)

func _add_controls_hint(root: Control) -> void:
	controls_hint = Label.new()
	controls_hint.text = "Tab 人物裝備｜H 教學｜M 地圖｜E 互動"
	controls_hint.position = Vector2(492, 614)
	controls_hint.add_theme_font_size_override("font_size", 13)
	root.add_child(controls_hint)

func _add_dialogue_box(root: Control) -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.add_to_group("dialogue_panel")
	dialogue_panel.position = Vector2(250, 500)
	dialogue_panel.custom_minimum_size = Vector2(780, 118)
	dialogue_panel.visible = false
	root.add_child(dialogue_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	dialogue_panel.add_child(stack)
	dialogue_speaker = Label.new()
	dialogue_speaker.add_theme_font_size_override("font_size", 18)
	stack.add_child(dialogue_speaker)
	dialogue_body = Label.new()
	dialogue_body.add_theme_font_size_override("font_size", 16)
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(dialogue_body)
	dialogue_timer = Timer.new()
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(func() -> void: dialogue_panel.visible = false)
	add_child(dialogue_timer)

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
	quest_label.text = "委託：%s" % GameState.active_quest_summary()
	_refresh_hotbar()

func _refresh_hotbar() -> void:
	if quick_bar == null:
		return
	for child in quick_bar.get_children():
		child.queue_free()
	for i in range(GameState.quick_slots.size()):
		var item_id := String(GameState.quick_slots[i])
		var button := Button.new()
		button.name = "QuickSlot%d" % [i + 1]
		button.custom_minimum_size = Vector2(88, 44)
		button.add_to_group("hotbar_slot")
		button.set_meta("quick_slot_index", i)
		button.text = "%d %s" % [i + 1, _short_name(item_id)]
		if i == GameState.active_quick_slot:
			button.text = "> " + button.text
		button.pressed.connect(GameState.use_quick_slot.bind(i))
		quick_bar.add_child(button)

func _refresh_inventory() -> void:
	if inventory_list == null:
		return
	for child in inventory_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "人物裝備"
	title.add_theme_font_size_override("font_size", 20)
	inventory_list.add_child(title)

	var active := Label.new()
	active.text = "目前左鍵：%s（%s）" % [GameState.item_display_name(GameState.active_attack_item_id()), _attack_mode_label(GameState.active_attack_mode())]
	active.add_theme_font_size_override("font_size", 15)
	inventory_list.add_child(active)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	inventory_list.add_child(body)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(178, 230)
	body.add_child(portrait_panel)
	var portrait_stack := VBoxContainer.new()
	portrait_stack.add_theme_constant_override("separation", 6)
	portrait_panel.add_child(portrait_stack)
	var portrait_title := Label.new()
	portrait_title.text = "回收商"
	portrait_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_stack.add_child(portrait_title)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(140, 156)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = PIXEL.new().player_texture(0, 0, 1)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_stack.add_child(portrait)
	var vitals := Label.new()
	vitals.text = "HP %d/%d\nEP %d/%d\n廢鐵 %d  核心 %d" % [
		GameState.hp,
		GameState.MAX_HP,
		GameState.ep,
		GameState.MAX_EP,
		GameState.scrap,
		GameState.cores
	]
	vitals.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_stack.add_child(vitals)

	var equipment_stack := VBoxContainer.new()
	equipment_stack.add_theme_constant_override("separation", 8)
	body.add_child(equipment_stack)
	var equipment_grid := GridContainer.new()
	equipment_grid.columns = 1
	equipment_grid.add_theme_constant_override("h_separation", 10)
	equipment_grid.add_theme_constant_override("v_separation", 8)
	equipment_stack.add_child(equipment_grid)
	_add_equipment_card(equipment_grid, "近戰武器", "weapon")
	_add_equipment_card(equipment_grid, "遠程武器", "ranged")
	_add_equipment_card(equipment_grid, "護甲", "armor")
	_add_equipment_card(equipment_grid, "工具", "tool")

	var stats := Label.new()
	stats.text = "屬性加成：攻擊 %+d　防禦 %+d　速度 %+d" % [
		GameState.get_stat_bonus("attack"),
		GameState.get_stat_bonus("defense"),
		GameState.get_stat_bonus("speed")
	]
	stats.add_theme_font_size_override("font_size", 14)
	equipment_stack.add_child(stats)

	var quest := Label.new()
	quest.text = "委託進度：%s" % GameState.active_quest_summary()
	quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipment_stack.add_child(quest)

	var separator := HSeparator.new()
	inventory_list.add_child(separator)
	var bag_title := Label.new()
	bag_title.text = "背包物品（點擊裝備可穿戴）"
	bag_title.add_theme_font_size_override("font_size", 16)
	inventory_list.add_child(bag_title)

	var bag_grid := GridContainer.new()
	bag_grid.columns = 3
	bag_grid.add_theme_constant_override("h_separation", 8)
	bag_grid.add_theme_constant_override("v_separation", 8)
	inventory_list.add_child(bag_grid)
	for item_id in GameState.inventory.keys():
		var amount := int(GameState.inventory[item_id])
		_add_bag_button(bag_grid, String(item_id), amount)

func _add_equipment_card(container: GridContainer, label_text: String, slot: String) -> void:
	var item_id := String(GameState.equipment.get(slot, ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 62)
	container.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(46, 46)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _item_icon(item_id)
	row.add_child(icon)
	var text := VBoxContainer.new()
	row.add_child(text)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	text.add_child(label)
	var value := Label.new()
	value.text = GameState.item_display_name(item_id)
	value.add_theme_font_size_override("font_size", 14)
	value.custom_minimum_size = Vector2(220, 0)
	value.clip_text = true
	text.add_child(value)

func _add_bag_button(container: GridContainer, item_id: String, amount: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 58)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s x%d" % [GameState.item_display_name(item_id), amount]
	button.icon = _item_icon(item_id)
	button.expand_icon = true
	button.pressed.connect(_equip_from_inventory.bind(item_id))
	container.add_child(button)

func _item_icon(item_id: String) -> Texture2D:
	var resource := DataRegistry.get_resource(item_id)
	if not resource.is_empty():
		return PIXEL.new().item_texture(item_id)
	var equipment := DataRegistry.get_equipment(item_id)
	if not equipment.is_empty():
		var mode := String(equipment.get("attack_mode", "passive"))
		if mode == "ranged":
			return PIXEL.new().item_texture("ammo")
		if mode == "melee":
			return PIXEL.new().item_texture("scrap")
		return PIXEL.new().item_texture("mutant_core")
	return PIXEL.new().item_texture("scrap")

func _equip_from_inventory(item_id: String) -> void:
	if not DataRegistry.get_equipment(item_id).is_empty():
		GameState.equip_item(item_id)

func _short_name(item_id: String) -> String:
	var name := GameState.item_display_name(item_id)
	if name.length() > 5:
		return name.substr(0, 5)
	return name

func _attack_mode_label(mode: String) -> String:
	match mode:
		"ranged":
			return "射擊"
		"melee":
			return "近戰"
		"tool":
			return "工具"
		_:
			return "近戰"

func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_label.visible = true
	notice_timer.start(2.2)

func _show_dialogue(speaker: String, role: String, message: String) -> void:
	dialogue_speaker.text = "%s｜%s" % [speaker, role]
	dialogue_body.text = message
	dialogue_panel.visible = true
	dialogue_timer.start(5.5)
