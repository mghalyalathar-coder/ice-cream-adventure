extends CharacterBody2D

# --- Pengaturan gerak (boleh diubah) ---
const SPEED := 180.0
const ACCEL := 1200.0
const FRICTION := 1400.0
const JUMP_VELOCITY := -380.0
const GRAVITY := 1000.0
const COYOTE_TIME := 0.1   # masih boleh lompat sesaat setelah jatuh dari tepi
const JUMP_BUFFER := 0.1   # tombol lompat "diingat" sesaat sebelum mendarat
const JUMP_CUT := 0.5      # lepas tombol lompat = lompatan lebih pendek

var coyote_timer := 0.0
var buffer_timer := 0.0
var invincible := false
var spawn_pos := Vector2.ZERO
var anim: AnimatedSprite2D
var jump_multiplier := 1.0   # pengali lompat saat power-up cokelat aktif
var power_time := 0.0        # sisa waktu power-up (detik); 0 = tidak aktif
var was_on_floor := false    # lantai frame lalu (deteksi mendarat)
var dust_timer := 0.0        # jeda antar puffs debu saat berlari


func _ready() -> void:
	add_to_group("player")
	spawn_pos = global_position
	_ensure_actions()
	_setup_sprite()


func _physics_process(delta: float) -> void:
	_tick_power_up(delta)

	# Gravitasi
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Coyote time dan jump buffer
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		buffer_timer = JUMP_BUFFER
	else:
		buffer_timer -= delta

	# Lompat (dikalikan multiplier saat power-up aktif)
	if buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY * jump_multiplier
		AudioManager.play_sfx("jump")
		buffer_timer = 0.0
		coyote_timer = 0.0

	# Lompat variabel: lepas tombol saat naik = lompatan lebih pendek
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Gerak kiri-kanan dengan akselerasi halus
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	var fall_speed := velocity.y   # kecepatan jelang menyentuh lantai
	move_and_slide()
	_update_animation(dir)

	# --- Efek debu (Langkah 13, murni visual) ---
	# Mendarat setelah melompat: satu letusan kecil
	if is_on_floor() and not was_on_floor and fall_speed > 250.0:
		_debu()
	# Mulai / terus berlari: puff kecil berkala (sedikit saja)
	dust_timer -= delta
	if is_on_floor() and absf(velocity.x) > 90.0 and dust_timer <= 0.0:
		dust_timer = 0.2
		_debu()
	was_on_floor = is_on_floor()


# Debu kecil di kaki pemain
func _debu() -> void:
	var fx: CPUParticles2D = preload("res://scenes/dust.tscn").instantiate()
	fx.global_position = global_position + Vector2(0, 14)
	get_parent().add_child(fx)


# Goyang kamera singkat saat kena damage: offset acak lewat Tween,
# total sekitar 0,2 detik, lalu kembali ke offset awal
func _shake_kamera() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var awal := cam.offset
	var tw := create_tween()
	for i in 3:
		tw.tween_property(cam, "offset", awal + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)), 0.05)
	tw.tween_property(cam, "offset", awal, 0.05)


func _update_animation(dir: float) -> void:
	if anim == null:
		return
	# Hadap sesuai arah gerak
	if dir < 0.0:
		anim.flip_h = true
	elif dir > 0.0:
		anim.flip_h = false

	var target := "idle"
	if not is_on_floor():
		target = "jump"
	elif absf(velocity.x) > 10.0:
		target = "run"

	if anim.animation != target:
		anim.play(target)


# --- Power-up topping cokelat (dipanggil powerup.gd) ---
# Lompat lebih tinggi + kebal damage selama durasi; warna sprite
# berubah menjadi cokelat muda, dan berkedip di 2 detik terakhir.
# Ambil lagi saat masih aktif = waktu direset penuh (tidak
# menumpuk, dan tidak ada dua timer yang jalan bersamaan).
func apply_power_up(durasi := 8.0) -> void:
	power_time = durasi
	jump_multiplier = 1.3
	if anim:
		anim.modulate = Color(0.87, 0.66, 0.5)   # cokelat muda


func _tick_power_up(delta: float) -> void:
	if power_time <= 0.0:
		return
	power_time -= delta
	if power_time <= 0.0:
		_end_power_up()
	elif power_time <= 2.0:
		# Efek hampir habis: animasi kedip via modulate.a
		if anim:
			anim.modulate.a = 0.45 + 0.55 * absf(sin(power_time * 8.0))


func _end_power_up() -> void:
	power_time = 0.0
	jump_multiplier = 1.0
	if anim:
		anim.modulate = Color(1, 1, 1)


# --- Dipanggil oleh spikes, slime, dan lainnya ---
func take_damage() -> void:
	if invincible or power_time > 0.0:   # kebal juga saat power-up aktif
		return
	invincible = true

	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("lose_life"):
		gm.lose_life()

	AudioManager.play_sfx("hurt")
	_shake_kamera()   # efek visual ringan (Langkah 13)

	# Berkedip
	if anim:
		var tw := create_tween()
		for i in 5:
			tw.tween_property(anim, "modulate:a", 0.3, 0.1)
			tw.tween_property(anim, "modulate:a", 1.0, 0.1)

	# Kebal selama 1 detik
	await get_tree().create_timer(1.0).timeout
	invincible = false
	if anim:
		anim.modulate.a = 1.0


func respawn() -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO


# Dipakai checkpoint nanti
func set_spawn(pos: Vector2) -> void:
	spawn_pos = pos


# --- Setup otomatis ---
func _setup_sprite() -> void:
	var old := get_node_or_null("Sprite2D") as Sprite2D
	anim = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim == null:
		anim = AnimatedSprite2D.new()
		anim.name = "AnimatedSprite2D"
		add_child(anim)

	# Sama dengan posisi dan ukuran sprite lama, lalu sembunyikan yang lama
	if old:
		anim.position = old.position
		anim.scale = old.scale
		anim.centered = old.centered
		anim.offset = old.offset
		old.visible = false

	# Pixel art tajam, tidak buram
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_anim(frames, "idle", ["res://assets/player_idle.png"], 5.0)
	_add_anim(frames, "run", ["res://assets/player_run1.png", "res://assets/player_run2.png"], 8.0)
	_add_anim(frames, "jump", ["res://assets/player_jump.png"], 5.0)
	anim.sprite_frames = frames
	anim.play("idle")


func _add_anim(frames: SpriteFrames, anim_name: String, paths: Array, fps: float) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, true)
	for p in paths:
		if ResourceLoader.exists(p):
			frames.add_frame(anim_name, load(p))


# Buat kontrol sendiri kalau belum ada di Input Map
func _ensure_actions() -> void:
	_make_action("move_left", [KEY_A, KEY_LEFT])
	_make_action("move_right", [KEY_D, KEY_RIGHT])
	_make_action("jump", [KEY_SPACE, KEY_W, KEY_UP])


func _make_action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action_name, ev)
