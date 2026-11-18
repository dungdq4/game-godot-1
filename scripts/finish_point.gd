extends Area2D

@export_file("*.tscn") var target_level: String

@onready var audio_stream_player = $AudioStreamPlayer2D

var is_transitioning: bool = false

func _on_body_entered(_body):
	if is_transitioning:
		return
	if target_level.is_empty():
		print("No target level specified!")
		return
	
	is_transitioning = true
	print("Level Completed! Moving to: ", target_level)
	if audio_stream_player:
		audio_stream_player.play()
	
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file(target_level)
