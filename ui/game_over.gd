extends CanvasLayer

# ============================================================
# Layar Game Over (ui/game_over.tscn)
# Muncul saat sinyal game_over dari GameManager (Autoload).
# process_mode di .tscn diset ALWAYS, jadi tombolnya tetap
# bisa diklik meski get_tree().paused = true (semua node lain
# berhenti, termasuk gerak pemain).
# ============================================================

# Scene menu utama
var menu_scene := "res://ui/main_menu.tscn"

@onready var retry_button: Button = $Center/RetryButton
@onready var menu_button: Button = $Center/MenuButton


func _ready() -> void:
	visible = false
	# Dengarkan GameManager (Autoload). Koneksi ikut terputus
	# otomatis saat scene ini dihapus.
	GameManager.game_over.connect(_on_game_over)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	AudioManager.pasang_klik(self)


# Saat nyawa habis: tampilkan layar, lalu pause seluruh scene
func _on_game_over() -> void:
	AudioManager.play_sfx("gameover")
	visible = true
	get_tree().paused = true


# Coba lagi: nyawa & koin direset, lalu level dimuat ulang
func _on_retry_pressed() -> void:
	GameManager.reset_run()
	GameManager.restart_level()   # restart_level() melepas pause sendiri


# Menu utama: kembali ke menu (nyawa/koin direset agar sesi baru bersih)
func _on_menu_pressed() -> void:
	GameManager.reset_run()
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene)
