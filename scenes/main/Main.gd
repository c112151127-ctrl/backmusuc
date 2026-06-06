extends Node2D

func _ready() -> void:
	print("Waste Recycler Main 場景載入成功")
	DataRegistry.load_all()
	await get_tree().process_frame
	SceneRouter.change_to("village", "default")
