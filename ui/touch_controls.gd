extends CanvasLayer

# ============================================================
# Tombol sentuh (Langkah 14): kiri / kanan di sisi kiri bawah,
# lompat di sisi kanan bawah, semi-transparan.
# - Memakai TouchScreenButton yang memicu action yang SUDAH ada:
#   "move_left", "move_right", "jump" (nama action sama yang
#   dibaca player.gd, jadi kontrol sentuh & keyboard berjalan
#   berdampingan tanpa saling mengganggu).
# - Dipasang SEKALI lewat GameManager (paling sederhana, persis
#   seperti pause menu): otomatis ada di semua level, tanpa
#   instance per level.
# - Hanya tampil jika: sedang di scene level (scene punya
#   finish_level), game tidak paused, DAN perangkat punya layar
#   sentuh menurut DisplayServer.is_touchscreen_available()
#   (atau "Emulate Touch From Mouse" aktif, untuk tes di PC).
# - Tekstur panah digambar lewat kode (16x16 px), jadi tidak
#   butuh file gambar baru.
# ============================================================


func _ready() -> void:
	$Left.texture_normal = _buat_tex("kiri")
	$Right.texture_normal = _buat_tex("kanan")
	$Jump.texture_normal = _buat_tex("lompat")


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var di_level: bool = scene != null and scene.has_method("finish_level")
	var ada_sentuh := DisplayServer.is_touchscreen_available()
	if not ada_sentuh:
		# Mengetes di PC tanpa HP: nilai dibaca dari pengaturan
		# proyek (diubah lewat menu editor, bukan lewat kode)
		ada_sentuh = ProjectSettings.get_setting(
			"input_devices/pointing/emulate_touch_from_mouse", false)
	# Sembunyikan juga saat paused (layar pause/gameover menutupi)
	visible = di_level and ada_sentuh and not get_tree().paused


# Gambar panah putih sederhana pada tekstur 16x16
func _buat_tex(tipe: String) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 16:
		for x in 16:
			var mid := absf(float(y) - 7.5)     # jarak dari baris tengah
			var midx := absf(float(x) - 7.5)    # jarak dari kolom tengah
			var tampil := false
			match tipe:
				"kiri":
					tampil = x <= 11 and x >= int(3.0 + mid)
				"kanan":
					tampil = x >= 4 and x <= int(12.0 - mid)
				"lompat":
					tampil = (y >= int(1.0 + midx) and y <= 7) \
						or (y >= 9 and y <= 13 and x >= 6 and x <= 9)
			if tampil:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
