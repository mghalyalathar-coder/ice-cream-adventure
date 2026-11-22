extends Area2D

# ============================================================
# Checkpoint: menyimpan titik spawn pemain (set_spawn di
# player.gd). Hanya aktif SEKALI; tampilan berubah:
# belum aktif = abu-abu, aktif = warna penuh (putih).
# Ganti Sprite2D texture di checkpoint.tscn kalau ada aset
# yang lebih cocok (mis. bendera kecil / tiang).
# ============================================================

var activated := false

@onready var visual: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if visual:
		visual.modulate = Color(0.45, 0.45, 0.5, 1.0)  # abu-abu = belum aktif


func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if not body.is_in_group("player"):
		return

	activated = true
	if body.has_method("set_spawn"):
		body.set_spawn(global_position)

	# Sudah dipakai -> berhenti mendeteksi (aktif sekali saja)
	set_deferred("monitoring", false)

	if visual:
		visual.modulate = Color(1, 1, 1)  # penuh warna = aktif
