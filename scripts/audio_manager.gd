extends Node

# ============================================================
# AudioManager (Autoload)
# Daftarkan lewat menu Godot: Project -> Project Settings ->
# Autoload -> path res://scripts/audio_manager.gd ->
# nama node PERSIS "AudioManager" -> Add.
#
# - Bus "Music" & "SFX" dibuat lewat kode di _ready (tidak
#   perlu file default_bus_layout).
# - play_sfx(): memakai pool AudioStreamPlayer supaya suara
#   bisa tumpang tindih (beberapa berbunyi bersamaan).
# - play_music(): lagu yang sama tidak diulang kalau masih
#   diputar; pindah lagu dengan fade singkat.
# - File suara dicari di res://audio/<nama>.ogg lalu .wav.
#   Kalau tidak ada -> dilewati diam-diam (cek pakai
#   ResourceLoader.exists), game tidak error.
# - Tekan M di mana saja = bisukan/hidupkan semua suara.
# ============================================================

const FOLDER := "res://audio/"

var pool: Array[AudioStreamPlayer] = []
var pool_idx := 0
var music_player: AudioStreamPlayer
var current_music := ""
var cache: Dictionary = {}
var music_tween: Tween


func _ready() -> void:
	# Musik tetap berbunyi saat game paused dan tombol M tetap bekerja
	process_mode = Node.PROCESS_MODE_ALWAYS
	_siapkan_bus("Music")
	_siapkan_bus("SFX")
	# Pemutar musik (satu)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	# Pool SFX (8 pemutar)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	# Terapkan volume & mute yang tersimpan (dibaca dari GameManager)
	apply_saved()


# Buat bus baru kalau belum ada
func _siapkan_bus(nama: String) -> void:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == nama:
			return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, nama)
	AudioServer.set_bus_send(idx, "Master")


# --- Suara & musik ---

func play_sfx(nama: String) -> void:
	var s := _ambil(nama)
	if s == null:
		return
	var p := pool[pool_idx]
	pool_idx = (pool_idx + 1) % pool.size()   # berputar: bisa tumpang tindih
	p.stream = s
	p.play()


func play_music(nama: String) -> void:
	# Lagu yang sama masih berbunyi -> jangan mengulang dari awal
	if current_music == nama and music_player.playing:
		return
	var s := _ambil(nama)
	if s == null:
		return
	current_music = nama
	if music_tween:
		music_tween.kill()
	if music_player.playing:
		# Fade singkat keluar lalu ganti lagu
		music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -40.0, 0.25)
		music_tween.tween_callback(_mulai_musik.bind(s))
	else:
		_mulai_musik(s)


func _mulai_musik(s: AudioStream) -> void:
	music_player.stream = s
	music_player.volume_db = -40.0
	music_player.play()
	if music_tween:
		music_tween.kill()
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", 0.0, 0.3)


# Cari audio/<nama>.ogg lalu .wav; tidak ada -> null (diabaikan)
func _ambil(nama: String) -> AudioStream:
	if cache.has(nama):
		return cache[nama]
	for ekst in [".ogg", ".wav"]:
		var path: String = FOLDER + nama + String(ekst)
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			cache[nama] = s
			return s
	cache[nama] = null
	return null


# --- Volume & mute ---

func set_music_volume(v: float) -> void:
	GameManager.music_volume = clampf(v, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, _ke_db(GameManager.music_volume))


func set_sfx_volume(v: float) -> void:
	GameManager.sfx_volume = clampf(v, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, _ke_db(GameManager.sfx_volume))


func toggle_mute() -> void:
	GameManager.muted = not GameManager.muted
	_set_mute(GameManager.muted)


func _set_mute(b: bool) -> void:
	for nama in ["Music", "SFX"]:
		var idx := AudioServer.get_bus_index(nama)
		if idx >= 0:
			AudioServer.set_bus_mute(idx, b)


func _ke_db(v: float) -> float:
	return -80.0 if v <= 0.0 else linear_to_db(v)


# Terapkan nilai tersimpan dari GameManager (dipanggil saat
# autoload siap, atau setelah load_game() selesai)
func apply_saved() -> void:
	set_music_volume(GameManager.music_volume)
	set_sfx_volume(GameManager.sfx_volume)
	_set_mute(GameManager.muted)


# Tombol M = bisukan semua suara (berlaku juga saat menu/pause)
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_M:
		toggle_mute()


# Sambungkan suara klik ke SEMUA tombol di bawah fungsi node akar.
# Dipanggil 1 baris dari tiap script UI: AudioManager.pasang_klik(self)
func pasang_klik(akar: Node) -> void:
	for anak in akar.get_children():
		if anak is Button:
			anak.pressed.connect(play_sfx.bind("click"))
		pasang_klik(anak)
