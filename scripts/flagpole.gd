extends Node2D

@export_file("*.tscn") var target_level: String

@onready var flag = $Flag
@onready var tap_sound = $TapSound
@onready var victory_sound = $VictorySound
@onready var coin_sound = $CoinSound
@onready var clear_ui = $CanvasLayer/ClearUI
@onready var score_label = $CanvasLayer/ClearUI/ScoreLabel
@onready var castle_door = $Castle/Door

var is_triggered: bool = false

# Top of the pole is at y = -110, base is at y = -16
const POLE_TOP_Y: float = -110.0
const POLE_BOTTOM_Y: float = -16.0

func _ready():
	clear_ui.visible = false

func _on_area_2d_body_entered(body):
	if is_triggered:
		return
	if not (body.is_in_group("player") or body.name == "Player"):
		return
		
	is_triggered = true
	
	# Pause background music
	var music = get_node_or_null("/root/Music")
	if music:
		music.stream_paused = true
		
	# Play touch sound
	if tap_sound:
		tap_sound.play()
		
	# Lock player controls
	if "is_cinematic" in body:
		body.is_cinematic = true
	body.velocity = Vector2.ZERO
	
	# Calculate score based on height touched
	var touch_y = body.global_position.y
	var pole_top_global = global_position.y + POLE_TOP_Y
	var pole_bottom_global = global_position.y + POLE_BOTTOM_Y
	var height_ratio = clamp((pole_bottom_global - touch_y) / (pole_bottom_global - pole_top_global), 0.0, 1.0)
	
	var earned_points: int = 400
	if height_ratio > 0.8:
		earned_points = 5000
	elif height_ratio > 0.5:
		earned_points = 2000
	elif height_ratio > 0.25:
		earned_points = 1000
	else:
		earned_points = 400
		
	# Add to game score
	var gm = get_node_or_null("%GameManager")
	if gm == null:
		gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("add_score"):
		gm.add_score(earned_points)
		
	# Align player to left side of the pole
	var pole_x = global_position.x
	body.global_position.x = pole_x - 6.0
	
	# Cling animation on pole
	var anim_sprite = body.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		anim_sprite.play("jump")
		anim_sprite.flip_h = false
		
	# Slide Flag down and Player down simultaneously
	var slide_target_y = pole_bottom_global
	var slide_dist = abs(slide_target_y - body.global_position.y)
	var slide_duration = max(0.6, slide_dist / 90.0)
	
	var slide_tween = create_tween().set_parallel(true)
	# Flag slides down
	slide_tween.tween_property(flag, "position:y", POLE_BOTTOM_Y - 2.0, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	# Player slides down
	slide_tween.tween_property(body, "global_position:y", slide_target_y, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await slide_tween.finished
	
	# Victory fanfare & coin sounds
	if victory_sound:
		victory_sound.play()
	if coin_sound:
		coin_sound.play()
		
	# Show "STAGE CLEAR!" banner
	score_label.text = "+" + str(earned_points) + " PTS"
	clear_ui.visible = true
	clear_ui.modulate.a = 0.0
	var ui_tween = create_tween()
	ui_tween.tween_property(clear_ui, "modulate:a", 1.0, 0.3)
	
	# Player hops over to the right side of the pole
	await get_tree().create_timer(0.2).timeout
	body.global_position.x = pole_x + 6.0
	if anim_sprite:
		anim_sprite.flip_h = false
		anim_sprite.play("idle")
		
	await get_tree().create_timer(0.3).timeout
	
	# Player walks automatically into the castle door
	var castle_door_global_x = castle_door.global_position.x + 6.0
	var walk_distance = abs(castle_door_global_x - body.global_position.x)
	var walk_duration = max(0.8, walk_distance / 50.0)
	
	if anim_sprite:
		anim_sprite.play("run")
		
	var walk_tween = create_tween()
	walk_tween.tween_property(body, "global_position:x", castle_door_global_x, walk_duration)
	await walk_tween.finished
	
	# Player enters castle and vanishes
	if anim_sprite:
		anim_sprite.play("idle")
	var fade_tween = create_tween()
	fade_tween.tween_property(body, "modulate:a", 0.0, 0.25)
	await fade_tween.finished
	
	# Wait for fanfare celebration
	await get_tree().create_timer(1.2).timeout
	
	# Resume music for next stage
	if music:
		music.stream_paused = false
		
	# Change to target level
	if not target_level.is_empty():
		get_tree().change_scene_to_file(target_level)
	else:
		print("No target level specified!")
