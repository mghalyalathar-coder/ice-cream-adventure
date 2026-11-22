extends CanvasLayer

# ============================================================
# Pause menu (ui/pause_menu.tscn). Dipasang SEKALI oleh
# GameManager._ready (node ini jadi anak GameManager, yang
# merupakan Autoload), jadi otomatis aktif di semua level tanpa
# perlu instance per level.
#
# process_mode = ALWAYS: tetap bekerja saat get_tree().paused.
#
# Aturan aman pause:
# - Hanya bisa dibuka di scene level (scene punya finish_level)
#   dan saat game tidak sedang paused. Karena layar Game Over /
#   Level Selesai / Menang langsung mem-pause scene, Esc tidak
#   akan membuka pause di atas layar-layar itu.
# - opened_by_memarker: pause yang menutup bukan pause ini
#   (mis. layar Game Over) tidak ikut dilepas oleh tombol
#   "Lanjut" pause ini.
# ============================================================

var opened_by_me := false

@onready var resume_button: Button = $Center/ResumeButton
@onready var retry_button: Button = $Center/RetryButton
@onready var menu_button: Button = $Center/MenuButton
@onready var musik_slider: HSlider = $Center/MusikSlider
@onready var sfx_slider: HSlider = $Center/SfxSlider


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	# Suara klik semua tombol pause
	AudioManager.pasang_klik(self)
	# Slider volume Musik & SFX: atur bus langsung lewat AudioManager
	musik_slider.value_changed.connect(_on_musik_slider)
	sfx_slider.value_changed.connect(_on_sfx_slider)
	musik_slider.drag_ended.connect(_on_slider_selesai)
	sfx_slider.drag_ended.connect(_on_slider_selesai)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):   # tombol Esc
		if get_tree().paused:
			# Esc hanya menutup jika pause ini = yang membuka
			if opened_by_me:
				_tutup()
		else:
			var scene := get_tree().current_scene
			# Hanya di dalam level (punya finish_level), bukan di menu
			if scene != null and scene.has_method("finish_level"):
				_buka()


func _buka() -> void:
	visible = true
	get_tree().paused = true      # semua node ikut berhenti
	opened_by_me = true
	# Slider selalu mencerminkan nilai tersimpan terkini
	musik_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume


func _on_musik_slider(v: float) -> void:
	AudioManager.set_music_volume(v)


func _on_sfx_slider(v: float) -> void:
	AudioManager.set_sfx_volume(v)


func _on_slider_selesai(_berubah: bool) -> void:
	# Simpan setelah slider selesai digeser (bukan tiap pergeseran)
	GameManager.save_game()


func _tutup() -> void:
	visible = false
	get_tree().paused = false     # WAJIB: lepas pause saat menyembunyikan
	opened_by_me = false


func _on_resume_pressed() -> void:
	_tutup()


func _on_retry_pressed() -> void:
	_tutup()                      # lepas pause dulu sebelum pindah scene
	# retry_level() mengembalikan koin level ini (anti hitung dobel)
	# dan mengisi nyawa penuh, berbeda dengan restart_level().
	GameManager.retry_level()


func _on_menu_pressed() -> void:
	_tutup()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
