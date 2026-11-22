extends AnimatableBody2D

# ============================================================
# Platform jatuh:
# 1) Pemain menginjak (TriggerZone tipis di atas permukaan)
# 2) Getar selama +-0,5 detik
# 3) Jatuh turun sampai keluar layar
# 4) Collision dimatikan & platform disembunyikan — pemain bebas
#    (tidak ikut hilang, tidak terjebak di dalam platform)
# 5) Setelah +-3 detik muncul lagi di posisi awal
#    (menunggu dulu kalau tempatnya masih dipenuhi pemain)
# ============================================================

enum State { IDLE, SHAKING, FALLING, WAITING }

const SHAKE_TIME := 0.5      # lama bergetar sebelum jatuh
const FALL_DISTANCE := 240.0 # cukup untuk keluar layar (kamera tinggi 360)
const FALL_TIME := 0.8
const RESPAWN_TIME := 3.0    # jeda sebelum muncul lagi

var state := State.IDLE
var start_pos := Vector2.ZERO

@onready var trigger: Area2D = $TriggerZone
@onready var body_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	start_pos = position


func _physics_process(_delta: float) -> void:
	if state != State.IDLE:
		return
	# Deteksi pemain yang MENGINJAK (bukan melompat naik dari bawah)
	for body in trigger.get_overlapping_bodies():
		if body.is_in_group("player") and body is CharacterBody2D and body.velocity.y >= 0.0:
			_start_shake()
			break


func _start_shake() -> void:
	state = State.SHAKING
	var tw := create_tween()
	var getaran := 2.0                # amplitudo getar kiri-kanan
	var langkah := SHAKE_TIME / 10.0  # 10 ayunan = +-0,5 detik
	for i in 10:
		var sisi := 1.0 if i % 2 == 0 else -1.0
		tw.tween_property(self, "position:x", start_pos.x + getaran * sisi, langkah)
	tw.tween_callback(_fall)


func _fall() -> void:
	state = State.FALLING
	var tw := create_tween()
	# EASE IN: mulai lambat lalu makin cepat, seperti jatuh sungguhan
	tw.tween_property(self, "position:y", start_pos.y + FALL_DISTANCE, FALL_TIME).set_ease(Tween.EASE_IN)
	tw.tween_callback(_despawn)


func _despawn() -> void:
	state = State.WAITING
	body_shape.set_deferred("disabled", true)
	trigger.set_deferred("monitoring", false)
	visible = false
	_respawn()


# Muncul lagi setelah jeda; tunggu juga kalau tempatnya masih ada pemain
func _respawn() -> void:
	await get_tree().create_timer(RESPAWN_TIME).timeout
	# Platform belum boleh tampil: kembalikan dulu ke posisi awal,
	# tampilnya ditunda sampai tempatnya kosong dari pemain
	position = start_pos
	trigger.set_deferred("monitoring", true)
	await get_tree().create_timer(0.1).timeout  # beri kesempatan physics mencatat overlap
	while _player_at_spawn():
		await get_tree().create_timer(1.0).timeout
	body_shape.set_deferred("disabled", false)
	visible = true
	state = State.IDLE


func _player_at_spawn() -> bool:
	for body in trigger.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false
