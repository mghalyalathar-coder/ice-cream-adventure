extends Area2D

# Koin: Area2D yang menambah koin lewat GameManager (Autoload).
# Bonus visual/suara (Langkah 12-13, gameplay tidak berubah):
# - koin melayang naik-turun pelan memakai Tween
# - sfx "coin" + letusan partikel kecil warna kuning saat diambil

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Melayang pelan naik-turun (tween bolak-balik, tanpa AnimationPlayer)
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "position:y", -4.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node) -> void:
	# Hanya node di grup "player" yang boleh mengambil koin
	if body.is_in_group("player"):
		AudioManager.play_sfx("coin")
		# Letusan kecil warna kuning (one_shot, hapus sendiri)
		var fx: CPUParticles2D = preload("res://scenes/coin_pop.tscn").instantiate()
		fx.global_position = global_position
		get_parent().add_child(fx)
		GameManager.add_coin()   # tambah koin di GameManager
		queue_free()             # hapus koin dari level
