extends CanvasLayer

const MINIMAP_VIEW := preload("res://scripts/ui/MiniMapView.gd")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

var root: Control
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
var dialogue_role: Label
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
	GameState.dialogue_closed.connect(_hide_dialogue)
	_refresh()
	_refresh_inventory()
	_layout()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		_set_inventory_visible(not inventory_panel.visible)
	if Input.is_action_just_pressed("toggle_minimap"):
		minimap_panel.visible = not minimap_panel.visible
		_refresh_overlay_visibility()
	if Input.is_action_just_pressed("toggle_help"):
		tutorial_panel.visible = not tutorial_panel.visible
		_refresh_overlay_visibility()
	_layout()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if inventory_panel.visible:
			_set_inventory_visible(false)
		elif tutorial_panel.visible:
			tutorial_panel.visible = false
			_refresh_overlay_visibility()
		elif minimap_panel.visible:
			minimap_panel.visible = false
			_refresh_overlay_visibility()
		elif dialogue_panel.visible:
			_hide_dialogue()

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	if quick_bar_panel != null:
		quick_bar_panel.position = Vector2(max(16, (size.x - 520.0) * 0.5), size.y - 76.0)
	if controls_hint != null:
		controls_hint.position = Vector2(max(16, (size.x - controls_hint.size.x) * 0.5), size.y - 108.0)
	if dialogue_panel != null:
		dialogue_panel.position = Vector2(max(24, (size.x - 840.0) * 0.5), size.y - 210.0)
	if minimap_panel != null:
		minimap_panel.position = Vector2(size.x - 250.0, 18.0)

func _build_hud() -> void:
	root = Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(16, 16)
	top_bar.custom_minimum_size = Vector2(560, 74)
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
	notice_label.position = Vector2(18, 100)
	notice_label.add_theme_font_size_override("font_size", 15)
	notice_label.visible = false
	root.add_child(notice_label)
	notice_timer = Timer.new()
	notice_timer.one_shot = true
	notice_timer.timeout.connect(func() -> void: notice_label.visible = false)
	add_child(notice_timer)

	_build_inventory_panel()
	_add_quick_bar()
	_add_minimap()
	_add_tutorial()
	_add_controls_hint()
	_add_dialogue_box()

func _build_inventory_panel() -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.add_to_group("equipment_panel")
	inventory_panel.position = Vector2(34, 92)
	inventory_panel.custom_minimum_size = Vector2(720, 560)
	inventory_panel.z_index = 50
	inventory_panel.visible = false
	root.add_child(inventory_panel)
	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(inventory_list)

func _add_quick_bar() -> void:
	quick_bar_panel = PanelContainer.new()
	quick_bar_panel.name = "QuickBarPanel"
	quick_bar_panel.custom_minimum_size = Vector2(520, 58)
	root.add_child(quick_bar_panel)
	quick_bar = HBoxContainer.new()
	quick_bar.name = "QuickBar"
	quick_bar.add_theme_constant_override("separation", 6)
	quick_bar_panel.add_child(quick_bar)

func _add_minimap() -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.add_to_group("minimap_panel")
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

func _add_tutorial() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.add_to_group("tutorial_panel")
	tutorial_panel.position = Vector2(780, 380)
	tutorial_panel.custom_minimum_size = Vector2(450, 236)
	tutorial_panel.visible = false
	root.add_child(tutorial_panel)
	var stack := VBoxContainer.new()
	tutorial_panel.add_child(stack)
	var title := Label.new()
	title.text = "R-17 操作教學"
	title.add_theme_font_size_override("font_size", 20)
	stack.add_child(title)
	var body := Label.new()
	body.text = "WASD：移動\n滑鼠左鍵：依目前裝備攻擊\n空白鍵：強制近戰\n右鍵 / K：遠程射擊\nE：互動 / 推進對話\nTab / I：人物裝備\n1-4 / Q：切換快捷裝備\nM：地圖\nF5 / F9：手動存檔 / 讀檔\nEsc：關閉面板"
	body.add_theme_font_size_override("font_size", 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)

func _add_controls_hint() -> void:
	controls_hint = Label.new()
	controls_hint.text = "Tab 人物裝備｜H 教學｜M 地圖｜E 互動"
	controls_hint.add_theme_font_size_override("font_size", 14)
	root.add_child(controls_hint)

func _add_dialogue_box() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.add_to_group("dialogue_panel")
	dialogue_panel.custom_minimum_size = Vector2(840, 150)
	dialogue_panel.z_index = 60
	dialogue_panel.visible = false
	root.add_child(dialogue_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	dialogue_panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(88, 104)
	portrait.texture = PIXEL.new().player_texture(0, 0, 1)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	row.add_child(stack)
	dialogue_speaker = Label.new()
	dialogue_speaker.add_theme_font_size_override("font_size", 18)
	stack.add_child(dialogue_speaker)
	dialogue_role = Label.new()
	dialogue_role.add_theme_font_size_override("font_size", 13)
	stack.add_child(dialogue_role)
	dialogue_body = Label.new()
	dialogue_body.add_theme_font_size_override("font_size", 16)
	dialogue_body.custom_minimum_size = Vector2(690, 60)
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(dialogue_body)
	var hint := Label.new()
	hint.text = "E 繼續｜Esc 關閉｜離開 NPC 會自動收起"
	hint.add_theme_font_size_override("font_size", 12)
	stack.add_child(hint)
	dialogue_timer = Timer.new()
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(_hide_dialogue)
	add_child(dialogue_timer)

func _set_inventory_visible(is_visible: bool) -> void:
	inventory_panel.visible = is_visible
	_refresh_overlay_visibility()
	if is_visible:
		_refresh_inventory()

func _refresh_overlay_visibility() -> void:
	var modal_open := inventory_panel.visible or tutorial_panel.visible or minimap_panel.visible or dialogue_panel.visible
	quick_bar_panel.visible = not modal_open
	controls_hint.visible = not modal_open

func _refresh() -> void:
	var route := DataRegistry.get_wasteland_route(GameState.current_route_id)
	var route_name := String(route.get("name", "村莊據點"))
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
	quest_label.text = "委託：%s｜路線：%s" % [GameState.active_quest_summary(), route_name]
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
		button.custom_minimum_size = Vector2(120, 44)
		button.add_to_group("hotbar_slot")
		button.set_meta("quick_slot_index", i)
		button.text = "%s%d %s" % ["> " if i == GameState.active_quick_slot else "", i + 1, _short_name(item_id)]
		button.icon = _item_icon(item_id)
		button.expand_icon = true
		button.pressed.connect(GameState.use_quick_slot.bind(i))
		quick_bar.add_child(button)

func _refresh_inventory() -> void:
	if inventory_list == null:
		return
	for child in inventory_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "人物裝備：R-17 回收機器人"
	title.add_theme_font_size_override("font_size", 22)
	inventory_list.add_child(title)

	var active := Label.new()
	active.text = "目前左鍵：%s（%s）" % [GameState.item_display_name(GameState.active_attack_item_id()), _attack_mode_label(GameState.active_attack_mode())]
	active.add_theme_font_size_override("font_size", 15)
	inventory_list.add_child(active)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	inventory_list.add_child(body)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(190, 250)
	body.add_child(portrait_panel)
	var portrait_stack := VBoxContainer.new()
	portrait_stack.add_theme_constant_override("separation", 6)
	portrait_panel.add_child(portrait_stack)
	var portrait_title := Label.new()
	portrait_title.text = "R-17"
	portrait_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_stack.add_child(portrait_title)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(150, 160)
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
	_add_equipment_card(equipment_stack, "近戰武器", "weapon")
	_add_equipment_card(equipment_stack, "遠程武器", "ranged")
	_add_equipment_card(equipment_stack, "護甲", "armor")
	_add_equipment_card(equipment_stack, "工具", "tool")
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

	inventory_list.add_child(HSeparator.new())
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
		_add_bag_button(bag_grid, String(item_id), int(GameState.inventory[item_id]))

func _add_equipment_card(container: VBoxContainer, label_text: String, slot: String) -> void:
	var item_id := String(GameState.equipment.get(slot, ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 62)
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
	value.add_theme_font_size_override("font_size", 15)
	text.add_child(value)

func _add_bag_button(container: GridContainer, item_id: String, amount: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(210, 58)
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
		if String(equipment.get("slot", "")) == "armor":
			return PIXEL.new().item_texture("mutant_core")
		return PIXEL.new().item_texture("bio_crystal")
	return PIXEL.new().item_texture("scrap")

func _equip_from_inventory(item_id: String) -> void:
	if not DataRegistry.get_equipment(item_id).is_empty():
		GameState.equip_item(item_id)
		_refresh_inventory()

func _short_name(item_id: String) -> String:
	var name := GameState.item_display_name(item_id)
	if name.length() > 6:
		return name.substr(0, 6)
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
			return "被動"

func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_label.visible = true
	notice_timer.start(2.2)

func _show_dialogue(speaker: String, role: String, message: String) -> void:
	dialogue_speaker.text = speaker
	dialogue_role.text = role
	dialogue_body.text = message
	dialogue_panel.visible = true
	dialogue_timer.start(8.0)
	_refresh_overlay_visibility()
	_layout()

func _hide_dialogue() -> void:
	dialogue_panel.visible = false
	dialogue_timer.stop()
	_refresh_overlay_visibility()
