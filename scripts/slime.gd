extends CharacterBody2D

# ============================================================
# Slime: musuh berpatroli.
# - Berjalan kiri-kanan; berbalik saat kena tembok atau saat
#   lantai di depannya habis (RayCast2D "EdgeRay", ke bawah-depan).
# - Pemain menyentuh sisi/bawah -> pemain take_damage().
# - Pemain JATUH menimpa StompZone di atas -> slime mati
#   (animasi pipih lalu hilang) dan pemain memantul kecil.
# ============================================================

const WALK_SPEED := 50.0
const GRAVITY := 1000.0
const RAY_OFFSET := 26.0   # jarak ray dari pusat, searah depan
const BOUNCE := -250.0     # pantulan pemain setelah menginjak

var dir := -1              # arah jalan: -1 = kiri, 1 = kanan
var dying := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var stomp_zone: Area2D = $StompZone
@onready var touch_zone: Area2D = $TouchZone


func _physics_process(delta: float) -> void:
	if dying:
		return

	# Gravitasi
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Berjalan tetap ke arah "dir"; hadapan sprite & ray mengikuti arah
	velocity.x = dir * WALK_SPEED
	sprite.flip_h = dir > 0
	edge_ray.position.x = RAY_OFFSET * dir

	move_and_slide()

	# Berbalik saat menabrak tembok
	if is_on_wall():
		dir = -dir
		velocity.x = dir * WALK_SPEED

	# Berbalik di tepi jurang: saat berdiri di lantai tapi lantai
	# di depan tidak ada lagi (ray bawah-depan tak kena apa pun)
	if is_on_floor() and not edge_ray.is_colliding():
		dir = -dir
		velocity.x = dir * WALK_SPEED

	# --- Deteksi pemain (diperiksa tiap frame, seperti pola spike.gd) ---

	# Sisi/bawah menyentuh pemain -> pemain terluka (take_damage
	# sendiri memegang masa kebal 1 detik, jadi aman dipanggil)
	for body in touch_zone.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage()

	# Pemain jatuh menimpa StompZone -> slime mati + pemain memantul
	for body in stomp_zone.get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body is CharacterBody2D and body.velocity.y > 0.0:
			body.velocity.y = BOUNCE
			die()
			break


# Slime mati: hentikan gerak & deteksi, animasi pipih, lalu hilang
func die() -> void:
	if dying:
		return
	dying = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	AudioManager.play_sfx("stomp")
	# Percikan partikel hijau selain animasi pipih (Langkah 13)
	var fx: CPUParticles2D = preload("res://scenes/slime_pop.tscn").instantiate()
	fx.global_position = global_position
	get_parent().add_child(fx)
	# Matikan benturan & deteksi supaya "mayat" tak mengganjal/melukai
	$CollisionShape2D.set_deferred("disabled", true)
	touch_zone.set_deferred("monitoring", false)
	stomp_zone.set_deferred("monitoring", false)
	# Animasi dipipihkan lalu dihapus dari pohon scene
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(2.8, 0.8), 0.12)
	tw.tween_property(sprite, "scale", Vector2(2.8, 0.0), 0.12)
	tw.tween_callback(queue_free)
