extends Node2D
func _ready() -> void:
	$AudioStreamPlayer.finished.connect(_on_audio_stream_player_finished)

func _on_audio_stream_player_finished() -> void:
	$AudioStreamPlayer.play()
