extends AnimatableBody2D

# ============================================================
# Platform bergerak: bolak-balik dengan Tween berulang
# (pergi sejauh "jarak" lalu pulang, tanpa batas).
# sync_to_physics aktif, jadi pemain yang berdiri di atasnya
# ikut bergerak oleh platform (bukan tergelincir).
# ============================================================

@export var horizontal := true  # true = gerak ke samping, false = naik-turun
@export var jarak := 150.0      # jarak tempuh dari titik awal (px)
@export var kecepatan := 60.0   # kecepatan (px/detik)

@onready var start_pos: Vector2 = position


func _ready() -> void:
	# Arah gerak: mendatar atau menurun tegak, sesuai "horizontal"
	var offset := Vector2(jarak, 0) if horizontal else Vector2(0, jarak)
	var durasi := jarak / maxf(kecepatan, 0.1)
	# Tween masuk tanpa batas: lari bolak-balik selamanya
	var tw := create_tween().set_loops()
	tw.tween_property(self, "position", start_pos + offset, durasi)
	tw.tween_property(self, "position", start_pos, durasi)
