extends Node2D

const SPEED = 60

var direction = 1
var is_dead = false

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurt_sound = $HurtSound
@onready var killzone = $Killzone

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dead:
		return
		
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	
	position.x += direction * SPEED * delta

func die_from_stomp(player):
	if is_dead:
		return
	is_dead = true
	
	# Make player bounce upwards
	if player.has_method("bounce"):
		player.bounce()
	elif "velocity" in player:
		player.velocity.y = -220.0
		
	# Disable collisions immediately so killzone cannot trigger
	if killzone:
		killzone.set_deferred("monitoring", false)
		var shape = killzone.get_node_or_null("CollisionShape2D")
		if shape:
			shape.set_deferred("disabled", true)
			
	var stomp_shape = get_node_or_null("StompArea/CollisionShape2D")
	if stomp_shape:
		stomp_shape.set_deferred("disabled", true)
		
	# Play hurt sound
	if hurt_sound:
		hurt_sound.play()
		
	# Squash animation (flatten like classic Goomba)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.3, 0.2), 0.08)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()

func _on_stomp_area_body_entered(body):
	if is_dead:
		return
	if body.name == "Player" or body.is_in_group("player"):
		if body.velocity.y > 0:
			die_from_stomp(body)
