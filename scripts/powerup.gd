extends Area2D

# ============================================================
# Power-up topping cokelat:
# - Melayang naik-turun pelan (Tween bolak-balik pada sprite).
# - Hanya body di grup "player" yang bisa mengambil.
# - Diambil -> apply_power_up() pada pemain (lompat lebih tinggi
#   dan kebal selama 8 detik), lalu power-up hilang.
# Efek lengkapnya ada di player.gd (pengali lompat, kebal,
# warna sprite, dan kedip 2 detik terakhir).
# ============================================================

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Melayang pelan naik-turun (satu tween, berulang tanpa batas)
	var tw := create_tween().set_loops()
	var naik := Vector2(0, -5.0)
	tw.tween_property(sprite, "position", naik, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "position", Vector2.ZERO, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("apply_power_up"):
		AudioManager.play_sfx("powerup")
		body.apply_power_up(8.0)  # diambil lagi saat aktif = waktu direset
		queue_free()
