extends Area2D

# ============================================================
# Duri: memukul pemain lewat take_damage().
# Selain sinyal body_entered, daftar body di dalam area diperiksa
# tiap frame fisika. Tujuannya: pemain yang kebal lalu tetap
# berdiri di duri akan kena lagi begitu masa kebalnya berakhir.
# ============================================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	# Cek juga body yang SUDAH berada di dalam area
	for body in get_overlapping_bodies():
		_hurt_if_player(body)


func _on_body_entered(body: Node2D) -> void:
	_hurt_if_player(body)


func _hurt_if_player(body: Node2D) -> void:
	# Hanya pemain (grup "player") yang bisa terluka
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
