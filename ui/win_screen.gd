extends CanvasLayer

# ============================================================
# Layar menang "KAMU MENANG!" — tampil saat bendera disentuh
# tetapi daftar level_paths sudah habis. process_mode = ALWAYS,
# jadi tombolnya tetap bisa diklik saat get_tree().paused = true.
# ============================================================

@onready var replay_button: Button = $Center/ReplayButton
@onready var menu_button: Button = $Center/MenuButton
@onready var exit_button: Button = $Center/ExitButton


func _ready() -> void:
	visible = false
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	AudioManager.pasang_klik(self)


# Dipanggil level.gd saat bendera disentuh di level terakhir
func open() -> void:
	AudioManager.play_sfx("win")
	$Center/TotalLabel.text = "Total koin: " + str(GameManager.total_coins)
	visible = true
	get_tree().paused = true


# Main Lagi: reset koin & nyawa, mulai dari level 1
func _on_replay_pressed() -> void:
	GameManager.reset_run()       # nyawa & (total) koin kembali nol
	GameManager.restart_level()   # melepas pause + memuat level_paths[0]


# Menu Utama: lepas pause, lalu balik ke menu utama
func _on_menu_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")


# Keluar permainan
func _on_exit_pressed() -> void:
	get_tree().quit()
