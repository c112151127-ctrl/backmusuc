extends RefCounted
class_name RuntimeAssetLoader

static func load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	if image.load(absolute_path) != OK:
		return null
	return ImageTexture.create_from_image(image)

static func load_wav(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var stream := AudioStreamWAV.load_from_file(absolute_path)
	return stream
