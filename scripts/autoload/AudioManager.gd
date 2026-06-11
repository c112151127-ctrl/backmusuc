extends Node

const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")

const MUSIC := {
	"village": "res://assets/audio/music_village.wav",
	"guild": "res://assets/audio/music_guild.wav",
	"wasteland": "res://assets/audio/music_wasteland.wav"
}

const SFX := {
	"melee": "res://assets/audio/sfx_melee.wav",
	"shoot": "res://assets/audio/sfx_shoot.wav",
	"hit": "res://assets/audio/sfx_hit.wav",
	"pickup": "res://assets/audio/sfx_pickup.wav",
	"interact": "res://assets/audio/sfx_interact.wav",
	"death": "res://assets/audio/sfx_death.wav"
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var current_music := ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -14.0
	music_player.finished.connect(func() -> void:
		if music_player.stream != null:
			music_player.play()
	)
	add_child(music_player)
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		sfx_players.append(player)
		add_child(player)

func play_music(id: String) -> void:
	if current_music == id:
		return
	var path := String(MUSIC.get(id, ""))
	if path.is_empty():
		return
	var stream := ASSET_LOADER.load_wav(path)
	if stream == null:
		return
	current_music = id
	music_player.stream = stream
	music_player.play()

func play_sfx(id: String) -> void:
	var path := String(SFX.get(id, ""))
	if path.is_empty() or sfx_players.is_empty():
		return
	var stream := ASSET_LOADER.load_wav(path)
	if stream == null:
		return
	var player := sfx_players[sfx_cursor % sfx_players.size()]
	sfx_cursor += 1
	player.stream = stream
	player.play()
