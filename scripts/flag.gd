extends Area2D

# ============================================================
# Bendera: dipicu SEKALI saja saat pemain menyentuh (guard
# "triggered" + monitoring dimatikan supaya tak terpicu ulang).
# Sisanya diurus level.gd lewat finish_level(): hentikan gerak
# pemain, lalu tampilkan layar Level Selesai atau layar Menang.
# ============================================================

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		set_deferred("monitoring", false)   # jangan picu dua kali
		var scene := get_tree().current_scene
		if scene.has_method("finish_level"):
			scene.finish_level()
