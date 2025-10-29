extends Node
class_name PositionCalculator

static func calculate_storing_positions(count: int, spacing: float, direction: Vector3, origin: Node3D) -> Array[Vector3]:
    var out: Array[Vector3] = []
    if count <= 0:
        return out

    var dir := direction
    if dir.length() == 0:
        dir = Vector3(1, 0, 0)
    dir = dir.normalized()

    var start_offset := -((count - 1) * spacing) / 2.0

    for i in range(count):
        var local_pos: Vector3 = dir * (start_offset + i * spacing)
        out.append(origin.to_global(local_pos))

    return out

static func calculate_bank_positions(total_count: int, spacing: float, direction: Vector3, bank_origin: Node3D) -> Array[Vector3]:
    var out: Array[Vector3] = []
    if total_count <= 0:
        return out

    var dir := direction
    if dir.length() == 0:
        dir = Vector3(1, 0, 0)
    dir = dir.normalized()

    var start_offset := -((total_count - 1) * spacing) / 2.0

    for i in range(total_count):
        var local_pos: Vector3 = dir * (start_offset + i * spacing)
        out.append(bank_origin.to_global(local_pos))

    return out
