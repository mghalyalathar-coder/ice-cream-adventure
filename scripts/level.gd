extends Node2D

# Level: mengatur HUD, respawn pemain, dan menang/kalah.
# Nyawa & koin disimpan di GameManager (Autoload),
# jadi level hanya mendengarkan sinyalnya.

var finished := false
var spawn_pos := Vector2.ZERO

@onready var coin_label: Label = $HUD/CoinLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var power_label: Label = $HUD/PowerLabel
@onready var hearts := [$HUD/Heart1, $HUD/Heart2, $HUD/Heart3]
@onready var level_complete_screen: CanvasLayer = $LevelCompleteScreen
@onready var win_screen: CanvasLayer = $WinScreen


func _ready() -> void:
	spawn_pos = $Player.global_position
	# Musik semua level (tidak diulang kalau sudah berbunyi)
	AudioManager.play_music("music_level")
	# Sambungkan sinyal dari GameManager (Autoload)
	GameManager.coin_changed.connect(_on_coin_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.game_over.connect(_on_game_over)
	# Tampilkan data yang sekarang tersimpan di GameManager
	update_hud()


# --- Sinyal dari GameManager -> update HUD ---

func _on_coin_changed(total: int) -> void:
	coin_label.text = "Koin: " + str(total)


func _on_lives_changed(lives: int) -> void:
	lives_label.text = "Nyawa: " + str(lives)
	for i in hearts.size():
		if i < lives:
			hearts[i].modulate = Color(1, 1, 1, 1)
		else:
			hearts[i].modulate = Color(0.2, 0.2, 0.2, 0.6)


func _on_game_over() -> void:
	# Tampilan "GAME OVER" + pause + tombol diurus layar
	# ui/game_over.tscn lewat sinyal GameManager.game_over.
	# Cukup tandai level selesai supaya hit berikutnya diabaikan.
	finished = true


# --- Fungsi bantu ---

func update_hud() -> void:
	# Paksa tampil ulang nilai terbaru dari GameManager
	_on_coin_changed(GameManager.coins)
	_on_lives_changed(GameManager.lives)


# Tampilkan sisa waktu power-up: cukup membaca keadaan pemain;
# label hanya terlihat selama efek masih aktif
func _process(_delta: float) -> void:
	var t: float = $Player.power_time
	power_label.visible = t > 0.0
	if power_label.visible:
		power_label.text = "Cokelat: %.1f dtk" % t


# --- Sementara: tombol tes nyawa & koin (hapus nanti) ---
# L = kurangi 1 nyawa, C = tambah 1 koin. Dipakai untuk mengetes
# HUD dan layar Game Over sebelum duri/zona jatuh tersambung
# ke pemain.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.keycode == KEY_L:
			GameManager.lose_life()
		elif key.keycode == KEY_C:
			GameManager.add_coin()


# Dipanggil player.gd saat kena duri / jatuh
func player_hit(respawn := false) -> void:
	if finished:
		return
	# Nyawa berkurang -> HUD update otomatis lewat sinyal
	GameManager.lose_life()
	if respawn or GameManager.lives <= 0:
		$Player.velocity = Vector2.ZERO
		$Player.set_deferred("global_position", spawn_pos)


# Dipanggil flag.gd saat pemain menyentuh bendera
# (flag.gd menjamin ini dipanggil sekali saja).
func finish_level() -> void:
	if finished:
		return
	finished = true
	# Hentikan gerak pemain langsung
	var player: CharacterBody2D = $Player
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	# Masih ada level berikutnya -> layar Level Selesai;
	# daftar level sudah habis -> layar menang
	if GameManager.current_level + 1 < GameManager.level_paths.size():
		level_complete_screen.open(GameManager.coins)
	else:
		# Run selesai: simpan rekor total koin sebelum layar menang
		GameManager.save_game()
		win_screen.open()
