extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# zona jatuh letaknya di bawah layar (Y > 400), duri letaknya di lantai
	if global_position.y > 400.0:
		if body.has_method("fall"):
			body.fall()
	elif body.has_method("hurt"):
		body.hurt()
