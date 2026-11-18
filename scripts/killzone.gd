extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	# If parent is an enemy that can be stomped
	var parent = get_parent()
	if parent and parent.has_method("die_from_stomp"):
		if parent.is_dead:
			return
		# If player is falling downwards onto the enemy from above
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 2:
			parent.die_from_stomp(body)
			return

	print("You died!")
	Engine.time_scale = 0.5
	if body.has_node("CollisionShape2D"):
		body.get_node("CollisionShape2D").queue_free()
	timer.start()


func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
