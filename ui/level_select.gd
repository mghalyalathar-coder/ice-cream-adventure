extends Control

# ============================================================
# Layar "Pilih Level" (ui/level_select.tscn).
# Tombol Level 1..5: nomor <= GameManager.unlocked_level bisa
# dimainkan; sisanya disabled dengan tulisan "(terkunci)".
# Nilai unlocked_level diisi mulai dari 1 (level 1 saja) dan
# naik tiap kali satu level selesai (lihat GameManager).
# ============================================================

@onready var grid: GridContainer = $Menu/Grid
@onready var back_button: Button = $Menu/BackButton


func _ready() -> void:
	# Suara klik semua tombol + musik menu
	AudioManager.pasang_klik(self)
	AudioManager.play_music("music_menu")
	# Tombol di dalam Grid dibaca sesuai urutan: anak ke-i = Level i
	var nomor := 1
	for b in grid.get_children():
		if b is Button:
			_siapkan_tombol(b, nomor)
			nomor += 1
	back_button.pressed.connect(_on_kembali_pressed)


func _siapkan_tombol(b: Button, nomor: int) -> void:
	b.pressed.connect(_on_level_pressed.bind(nomor))
	if nomor <= GameManager.unlocked_level:
		b.text = "Level " + str(nomor)
		b.disabled = false
	else:
		b.text = "Level " + str(nomor) + "\n(terkunci)"
		b.disabled = true


func _on_level_pressed(nomor: int) -> void:
	# start_level menolak nomor yang masih terkunci (double guard)
	GameManager.start_level(nomor)


func _on_kembali_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
