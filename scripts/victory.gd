extends Control

@onready var play_again_button = $CenterContainer/VBoxContainer/PlayAgainButton

func _ready():
	if play_again_button:
		play_again_button.grab_focus()

func _process(_delta):
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		_on_play_again_pressed()

func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
