extends RefCounted
class_name InventorySystem

static func craft_basic_upgrade() -> bool:
	return craft_recipe("spark_cutter")

static func forge_ammo_pack() -> bool:
	return craft_recipe("ammo_pack")

static func craft_recipe(recipe_id: String) -> bool:
	var recipe := DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		GameState.notify("找不到配方：%s" % recipe_id)
		return false
	var cost: Dictionary = recipe.get("cost", {})
	for item_id in cost.keys():
		if int(GameState.inventory.get(String(item_id), 0)) < int(cost[item_id]):
			GameState.notify("材料不足：%s 需要 %d" % [_item_name(String(item_id)), int(cost[item_id])])
			return false
	for item_id in cost.keys():
		GameState.consume_item(String(item_id), int(cost[item_id]))
	var result: Dictionary = recipe.get("result", {})
	for item_id in result.keys():
		GameState.add_item(String(item_id), int(result[item_id]))
	GameState.notify("製作完成：%s" % String(recipe.get("name", recipe_id)))
	return true

static func shop_buy_ammo() -> bool:
	return craft_recipe("shop_ammo")

static func craft_coil_launcher() -> bool:
	return craft_recipe("coil_launcher")

static func recycle_core() -> bool:
	return craft_recipe("recycle_core")

static func _item_name(item_id: String) -> String:
	var resource := DataRegistry.get_resource(item_id)
	if not resource.is_empty():
		return String(resource.get("name", item_id))
	var equipment := DataRegistry.get_equipment(item_id)
	if not equipment.is_empty():
		return String(equipment.get("name", item_id))
	return item_id
