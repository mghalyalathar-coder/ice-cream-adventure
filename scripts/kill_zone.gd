extends Area2D

# ============================================================
# Zona jatuh (jurang): saat pemain masuk, kurangi 1 nyawa lalu
# kembalikan pemain ke titik checkpoint terakhir (spawn_pos di
# player.gd, diatur lewat set_spawn oleh checkpoint).
# Kalau nyawa sudah habis, JANGAN respawn — biarkan layar
# Game Over tampil.
# ============================================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	GameManager.lose_life()

	# Nyawa masih ada -> kembalikan pemain ke checkpoint terakhir
	if GameManager.lives > 0 and body.has_method("respawn"):
		body.respawn()
