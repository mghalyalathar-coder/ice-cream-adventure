extends Control

# ============================================================
# Menu utama (ui/main_menu.tscn).
# - "Mulai": reset nyawa & koin, lalu mulai Level 1.
# - "Pilih Level": buka layar pilih level.
# - "Reset Data": hapus user://save.cfg setelah konfirmasi.
# - "Keluar": tutup game.
# Label menampilkan data yang dimuat GameManager.load_game():
# rekor total koin seluruh run terbaik (bukan koin run ini).
# ============================================================

@onready var start_button: Button = $Menu/StartButton
@onready var level_button: Button = $Menu/LevelButton
@onready var reset_button: Button = $Menu/ResetButton
@onready var exit_button: Button = $Menu/ExitButton
@onready var total_label: Label = $Menu/TotalLabel
@onready var reset_dialog: ConfirmationDialog = $ResetDialog
@onready var musik_slider: HSlider = $Menu/MusikSlider
@onready var sfx_slider: HSlider = $Menu/SfxSlider


func _ready() -> void:
	start_button.pressed.connect(_on_mulai_pressed)
	level_button.pressed.connect(_on_pilih_level_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	exit_button.pressed.connect(_on_keluar_pressed)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	# Suara klik untuk semua tombol menu + musik menu
	AudioManager.pasang_klik(self)
	AudioManager.play_music("music_menu")
	# Slider volume: mulai dari nilai tersimpan
	musik_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	musik_slider.value_changed.connect(_on_musik_slider)
	sfx_slider.value_changed.connect(_on_sfx_slider)
	musik_slider.drag_ended.connect(_on_slider_selesai)
	sfx_slider.drag_ended.connect(_on_slider_selesai)
	# Tampilkan rekor koin hasil load_game() (autoload sudah lebih
	# dulu memuat save.cfg). Scene ini dibuat ulang tiap kali dibuka,
	# jadi label selalu segar.
	_perbarui_label()


func _on_musik_slider(v: float) -> void:
	AudioManager.set_music_volume(v)


func _on_sfx_slider(v: float) -> void:
	AudioManager.set_sfx_volume(v)


func _on_slider_selesai(_berubah: bool) -> void:
	# Simpan setelah slider selesai digeser (bukan tiap pergeseran)
	GameManager.save_game()


func _perbarui_label() -> void:
	total_label.text = "Rekor koin: %d" % GameManager.best_total_coins


# Mulai dari level 1 dengan nyawa & koin direset
func _on_mulai_pressed() -> void:
	GameManager.reset_run()
	GameManager.start_level(1)


func _on_pilih_level_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/level_select.tscn")


# Popup konfirmasi dulu, baru data dihapus
func _on_reset_pressed() -> void:
	reset_dialog.popup_centered()


# Tekan "Hapus" pada dialog -> jalankan penghapusan
func _on_reset_confirmed() -> void:
	GameManager.delete_save()
	_perbarui_label()


func _on_keluar_pressed() -> void:
	get_tree().quit()
