extends CanvasLayer

# ============================================================
# Layar "LEVEL SELESAI!" — tampil saat bendera disentuh dan
# masih ada level berikutnya. process_mode = ALWAYS, jadi
# tombolnya tetap bisa diklik saat get_tree().paused = true.
# Tombol "Lanjut": transisi fade gelap, lalu pindah level.
# Tombol "Menu Utama": kembali ke menu (pause dilepas dulu).
# ============================================================

@onready var next_button: Button = $Center/NextButton
@onready var menu_button: Button = $Center/MenuButton
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	AudioManager.pasang_klik(self)


# Dipanggil level.gd saat bendera disentuh
func open(coins_level: int) -> void:
	AudioManager.play_sfx("win")
	$Center/CoinsLabel.text = "Koin level ini: " + str(coins_level)
	visible = true
	get_tree().paused = true


func _on_next_pressed() -> void:
	# Cegah klik ganda saat transisi jalan
	next_button.disabled = true
	# Fade gelap dulu (tween tetap jalan walau scene paused,
	# karena layar ini process_mode ALWAYS)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	# WAJIB: lepaskan pause sebelum scene baru dimuat
	get_tree().paused = false
	GameManager.next_level()


# Menu Utama: lepas pause, lalu balik ke menu utama
func _on_menu_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
