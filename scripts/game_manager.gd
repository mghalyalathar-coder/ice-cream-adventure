extends Node

# ============================================================
# GameManager (Autoload)
# Menyimpan data game global: nyawa, koin, level sekarang,
# dan daftar path level. Semua scene memakai ini lewat
# sinyal supaya HUD selalu sinkron.
# ============================================================

# Sinyal: HUD tinggal dengarkan ini, tidak perlu update manual
signal coin_changed(total: int)       # terus saat koin berubah
signal lives_changed(lives: int)      # terus saat nyawa berubah
signal game_over                       # terus saat nyawa habis

const MAX_LIVES := 3                   # nyawa maksimal

var lives: int = MAX_LIVES             # nyawa sekarang
var coins: int = 0                     # koin level yang sedang dimainkan
var total_coins: int = 0               # total koin semua level (hanya nol di reset_run)
var current_level: int = 0             # indeks level sekarang (mulai 0)
var unlocked_level: int = 1            # level tertinggi yang boleh dipilih (mulai 1)
var best_total_coins: int = 0          # rekor total koin run terbaik; disimpan ke file
var level_coins_start: int = 0         # koin yang sudah ada saat level ini dimulai (anti hitung dobel)

const SAVE_PATH := "user://save.cfg"   # lokasi file simpanan (bisa dilihat via Project -> Open User Data Folder)

# Pengaturan audio (0..1) & status mute — ikut tersimpan di save.cfg
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var muted := false

# Daftar path level - tambah level baru di sini
var level_paths: Array[String] = [
	"res://scenes/level.tscn",
	"res://scenes/level2.tscn",
	"res://scenes/level3.tscn",
	"res://scenes/level4.tscn",
	"res://scenes/level5.tscn",
]


func _ready() -> void:
	# Mulai permainan: nyawa penuh, koin nol
	reset_run()
	# Muat simpanan (level terbuka & rekor koin) saat game dibuka.
	# Kalau file belum ada / rusak, nilai awal tetap dipakai.
	load_game()
	# Pause menu & kontrol sentuh DIPASANG DITUNDA (call_deferred).
	# Alasan: saat _ready GameManager (autoload PERTAMA) berjalan,
	# autoload AudioManager (kedua) belum terpasang di pohon —
	# padahal _ready pause_menu memanggil
	# AudioManager.pasang_klik(). Dengan call_deferred pemasangan
	# baru berjalan di akhir frame startup, saat SEMUA autoload
	# sudah siap -> tidak ada lagi error 'pasang_klik in base Nil'.
	call_deferred("_pasang_layer_tambahan")


# Pemasangan layer tambahan sekali saja (pause menu + sentuh).
func _pasang_layer_tambahan() -> void:
	# Pause menu dipasang SEKALI di Autoload (bukan instance per
	# level), jadi pilihan paling sederhana: otomatis aktif di
	# semua level dan tidak perlu menyentuh scene level sama sekali.
	var pause_scene: PackedScene = load("res://ui/pause_menu.tscn")
	add_child(pause_scene.instantiate())
	# Kontrol sentuh dipasang cara yang sama; ia menyembunyikan
	# dirinya sendiri kecuali di level + perangkat sentuh.
	var touch_scene: PackedScene = load("res://ui/touch_controls.tscn")
	add_child(touch_scene.instantiate())


# Tambah 1 koin (dipanggil coin.gd saat disentuh pemain)
func add_coin() -> void:
	coins += 1
	total_coins += 1   # total kumpulan semua level, tidak pernah berkurang
	coin_changed.emit(coins)


# Kurangi 1 nyawa; kalau habis, teruskan sinyal game_over
func lose_life() -> void:
	lives -= 1
	if lives < 0:
		lives = 0
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()


# Reset permainan dari awal (nyawa penuh, koin nol, level pertama).
# unlocked_level & best_total_coins TIDAK disentuh di sini.
func reset_run() -> void:
	lives = MAX_LIVES
	coins = 0
	total_coins = 0
	current_level = 0
	level_coins_start = 0
	coin_changed.emit(coins)
	lives_changed.emit(lives)


# Pindah ke level berikutnya;
# kalau sudah level terakhir, ulang dari awal dengan reset
func next_level() -> void:
	if current_level + 1 < level_paths.size():
		current_level += 1
		# Menyelesaikan level membuka level berikutnya di Pilih Level
		unlocked_level = maxi(unlocked_level, current_level + 1)
		# Koin level direset: di level baru kumpulan dimulai dari nol
		coins = 0
		level_coins_start = 0
		coin_changed.emit(coins)
		# Simpan otomatis saat level selesai: level terbuka baru +
		# rekor koin run sejauh ini
		save_game()
		get_tree().change_scene_to_file(level_paths[current_level])
	else:
		# Sudah level terakhir -> main dari awal lagi
		reset_run()
		get_tree().change_scene_to_file(level_paths[0])


# Mulai level tertentu (nomor 1-based, dari layar Pilih Level).
# Menolak nomor di luar daftar atau yang masih terkunci.
func start_level(nomor: int) -> void:
	if nomor < 1 or nomor > level_paths.size():
		return
	if nomor > unlocked_level:
		return
	current_level = nomor - 1
	lives = MAX_LIVES
	coins = 0
	# Memilih level dari menu = memulai run baru dari level itu,
	# jadi sisa total koin run sebelumnya tidak dibawa-bawa
	total_coins = 0
	level_coins_start = 0
	coin_changed.emit(coins)
	lives_changed.emit(lives)
	get_tree().paused = false
	get_tree().change_scene_to_file(level_paths[current_level])


# Muat ulang level sekarang (nyawa/koin tidak direset)
func restart_level() -> void:
	# Pastikan pause dilepas (biasanya masuk dari layar Game Over),
	# kalau tidak level baru ikut terpause dan pemain tidak bisa bergerak.
	get_tree().paused = false
	get_tree().change_scene_to_file(level_paths[current_level])


# "Ulangi Level" dari pause menu: level diulang dari awal.
# Koin yang terkumpul DI LEVEL INI dikembalikan supaya tidak
# dihitung dobel kalau dikumpulkan lagi (aturan tanpa hitung dobel).
func retry_level() -> void:
	total_coins -= (coins - level_coins_start)
	coins = level_coins_start
	level_coins_start = coins
	lives = MAX_LIVES
	coin_changed.emit(coins)
	lives_changed.emit(lives)
	get_tree().paused = false
	get_tree().change_scene_to_file(level_paths[current_level])


# ============================================================
# Simpan & muat (ConfigFile ke user://save.cfg)
# Isi file:
#   [progres] unlocked_level  = level tertinggi yang bisa dipilih
#             best_total_coins = rekor total koin run terbaik
# ============================================================

# Aturan anti hitung dobel: koin yang tersimpan adalah
# max(rekor lama, total run ini). Jadi:
# - Main lebih bagus -> rekor naik.
# - Main ulang dengan total lebih kecil -> rekor tetap.
# - Ulang level yang sama tidak pernah menggandakan hitungan.
func save_game() -> void:
	best_total_coins = maxi(best_total_coins, total_coins)
	var cfg := ConfigFile.new()
	cfg.set_value("progres", "unlocked_level", unlocked_level)
	cfg.set_value("progres", "best_total_coins", best_total_coins)
	# Pengaturan audio ikut disimpan supaya tidak diatur ulang tiap main
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	# Kalau file tidak ada atau rusak -> load() gagal, return diam-diam;
	# nilai awal (unlocked_level=1, best_total_coins=0) tetap terpakai.
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var u = cfg.get_value("progres", "unlocked_level", 1)
	var c = cfg.get_value("progres", "best_total_coins", 0)
	# Jaga-jaga kalau isi file diubah manual jadi tipe aneh
	if typeof(u) in [TYPE_INT, TYPE_FLOAT]:
		unlocked_level = clampi(int(u), 1, level_paths.size())
	if typeof(c) in [TYPE_INT, TYPE_FLOAT]:
		best_total_coins = maxi(0, int(c))
	# Tiga angka audio: nilai default dipakai kalau seksi tidak ada
	var m = cfg.get_value("audio", "music_volume", music_volume)
	var s = cfg.get_value("audio", "sfx_volume", sfx_volume)
	var t = cfg.get_value("audio", "muted", muted)
	if typeof(m) in [TYPE_INT, TYPE_FLOAT]:
		music_volume = clampf(float(m), 0.0, 1.0)
	if typeof(s) in [TYPE_INT, TYPE_FLOAT]:
		sfx_volume = clampf(float(s), 0.0, 1.0)
	if typeof(t) == TYPE_BOOL:
		muted = t
	# Kalau AudioManager sudah masuk pohon (tergantung urutan
	# autoload), langsung diterapkan. Kalau belum, _ready
	# AudioManager yang akan menerapkan nilainya.
	if get_node_or_null("/root/AudioManager") != null:
		AudioManager.apply_saved()


# Hapus file simpanan + kembalikan ke nilai awal (tombol Reset Data)
func delete_save() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("save.cfg"):
		dir.remove("save.cfg")
	unlocked_level = 1
	best_total_coins = 0
