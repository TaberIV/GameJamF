extends Area2D

class_name Hurtbox

signal take_damage(dir)
signal die

export var max_health: float = 100
export var faction: String = "player"

# Health state
var health: float


func _ready() -> void:
    health = max_health


func _on_Hurtbox_area_entered(hit: Hitbox) -> void:
    if get_parent().hit:
        return
    if hit:
        if hit.faction != faction:
            health = max(health - hit.damage, 0)

            if health == 0:
                emit_signal("die")
            var dir = 1 if hit.global_position.x > global_position.x else -1
            emit_signal("take_damage", dir)
            $HitSound.play()