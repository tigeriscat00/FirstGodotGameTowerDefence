class_name StageOneWaves
extends Resource
## Editable roster from the owner's plan, with a provisional wave-five boss.

@export var starting_coins: int = 200
@export var preparation_seconds: float = 10.0
# Each entry is standard, dog, toilet, finale. The finale is a semiboss in
# waves 2-4 and a boss in wave 5; wave 1 has no finale in the listed roster.
@export var wave_1: Array[int] = [5, 2, 1, 0]
@export var wave_2: Array[int] = [6, 3, 0, 1]
@export var wave_3: Array[int] = [7, 2, 1, 1]
@export var wave_4: Array[int] = [9, 2, 2, 1]
@export var wave_5: Array[int] = [10, 5, 4, 1]


func roster(wave: int) -> Array[int]:
	match wave:
		1: return wave_1.duplicate()
		2: return wave_2.duplicate()
		3: return wave_3.duplicate()
		4: return wave_4.duplicate()
		5: return wave_5.duplicate()
		_: return []
