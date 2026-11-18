extends Node

var score = 0

@onready var score_label = $ScoreLabel

func add_point():
	add_score(1)

func add_score(amount: int):
	score += amount
	if score_label:
		score_label.text = "You collected " + str(score) + " coins."
