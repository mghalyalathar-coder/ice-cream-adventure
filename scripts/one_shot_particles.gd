extends CPUParticles2D

# Partikel sekali-tembak (one_shot): menyala begitu node siap dan
# menghapus dirinya sendiri setelah efek selesai. Dipakai bersama:
# coin_pop, dust, dan slime_pop. Ringan: jumlah partikel < 20 per
# efek; pakai CPUParticles2D agar aman di mode Compatibility.
func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime + 0.4).timeout
	queue_free()
