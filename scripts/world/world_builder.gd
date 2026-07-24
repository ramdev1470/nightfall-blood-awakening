class_name WorldBuilder
extends RefCounted
## Builds "The Hollow" — one continuous gothic map — out of CSG primitives.
## No external assets are referenced; every surface gets a proper material so
## the level reads as an intentional gothic town rather than test geometry.

const STONE := Color(0.157, 0.161, 0.192)
const STONE_DARK := Color(0.086, 0.09, 0.11)
const STONE_LIGHT := Color(0.24, 0.235, 0.26)
const WOOD := Color(0.11, 0.07, 0.05)
const ROOF := Color(0.06, 0.05, 0.075)
const IRON := Color(0.05, 0.05, 0.06)
const GRASS_DEAD := Color(0.09, 0.1, 0.07)
const ROAD_DIRT := Color(0.08, 0.075, 0.07)
const LANTERN_WARM := Color(1.0, 0.62, 0.28)
const LANTERN_VIOLET := Color(0.62, 0.42, 1.0)
const MOON_BLUE := Color(0.55, 0.63, 0.95)
const BLOOD := Color(0.28, 0.02, 0.03)

static func build(root: Node3D) -> Dictionary:
	var landmarks := {}
	_build_ground(root)
	_build_forest_road(root)
	landmarks["gate_trigger_z"] = 30.0
	_build_gate(root)
	_build_town_square(root)
	landmarks["square_trigger_z"] = 8.0
	var church_data := _build_church(root)
	landmarks["church_door"] = church_data["door"]
	landmarks["church_interior"] = church_data["interior"]
	_build_graveyard(root)
	landmarks["ambush_point"] = Vector3(9.0, 0.0, -9.0)
	_build_forest_edge(root)
	_build_catacomb_entrance(root)
	landmarks["player_spawn"] = Vector3(0.0, 1.2, 56.0)
	return landmarks

# ---------------------------------------------------------------- materials

static func _mat(color: Color, rough: float = 0.85, metal: float = 0.0, emission: Color = Color(0, 0, 0), emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	return m

# ---------------------------------------------------------------- primitives

static func _box(parent: Node3D, name: String, size: Vector3, pos: Vector3, material: Material, rot_deg: Vector3 = Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = name
	b.size = size
	b.position = pos
	b.rotation_degrees = rot_deg
	b.use_collision = true
	b.material = material
	parent.add_child(b)
	return b

static func _cyl(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, material: Material, sides: int = 8, cone: bool = false, rot_deg: Vector3 = Vector3.ZERO) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.name = name
	c.radius = radius
	c.height = height
	c.sides = sides
	c.cone = cone
	c.position = pos
	c.rotation_degrees = rot_deg
	c.use_collision = true
	c.material = material
	parent.add_child(c)
	return c

static func _lamp(parent: Node3D, pos: Vector3, color: Color = LANTERN_WARM, energy: float = 3.0) -> void:
	_cyl(parent, "LampPost", 0.07, 3.0, pos + Vector3(0, 1.5, 0), _mat(IRON, 0.5, 0.6))
	var glass := _cyl(parent, "LampGlass", 0.18, 0.32, pos + Vector3(0, 3.05, 0), _mat(color, 0.2, 0.0, color, 2.2))
	glass.use_collision = false
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 3.05, 0)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 9.0
	light.shadow_enabled = false
	parent.add_child(light)
	_attach_flicker(light, energy)

static func _attach_flicker(light: Light3D, base_energy: float) -> void:
	var tween := light.create_tween()
	tween.set_loops()
	tween.tween_property(light, "light_energy", base_energy * 0.75, 0.6 + randf() * 0.4)
	tween.tween_property(light, "light_energy", base_energy * 1.05, 0.5 + randf() * 0.5)

static func _tree(parent: Node3D, pos: Vector3, scale_mul: float = 1.0) -> void:
	var h := (4.5 + randf() * 3.0) * scale_mul
	_cyl(parent, "TreeTrunk", 0.32 * scale_mul, h, pos + Vector3(0, h * 0.5, 0), _mat(Color(0.05, 0.04, 0.035), 1.0))
	var canopy_h := 5.0 * scale_mul
	var canopy := _cyl(parent, "TreeCanopy", 2.2 * scale_mul, canopy_h, pos + Vector3(0, h + canopy_h * 0.35, 0), _mat(Color(0.03, 0.05, 0.035), 0.95), 7, true)
	canopy.use_collision = false

static func _tombstone(parent: Node3D, pos: Vector3, rot_y: float) -> void:
	var kind := randi() % 3
	if kind == 0:
		_box(parent, "Tombstone", Vector3(0.7, 1.1, 0.15), pos + Vector3(0, 0.55, 0), _mat(STONE_DARK, 1.0), Vector3(0, rot_y, 0))
	elif kind == 1:
		_cyl(parent, "TombArch", 0.35, 0.15, pos + Vector3(0, 1.0, 0), _mat(STONE, 1.0), 8, false, Vector3(90, rot_y, 0))
		_box(parent, "TombBase", Vector3(0.6, 0.9, 0.15), pos + Vector3(0, 0.45, 0), _mat(STONE, 1.0), Vector3(0, rot_y, 0))
	else:
		_box(parent, "TombSlab", Vector3(1.4, 0.25, 0.7), pos + Vector3(0, 0.12, 0), _mat(STONE_DARK, 1.0), Vector3(0, rot_y, 0))

static func _fence_run(parent: Node3D, start: Vector3, end: Vector3, height: float = 1.1) -> void:
	var dist := start.distance_to(end)
	var dir := (end - start).normalized()
	var count: int = max(2, int(dist / 1.4))
	var rot_y := rad_to_deg(atan2(dir.x, dir.z))
	for i in count + 1:
		var p := start.lerp(end, float(i) / float(count))
		_box(parent, "FencePost", Vector3(0.08, height, 0.08), p + Vector3(0, height * 0.5, 0), _mat(IRON, 0.4, 0.7))
	_box(parent, "FenceRail", Vector3(0.05, 0.05, dist), start.lerp(end, 0.5) + Vector3(0, height * 0.85, 0), _mat(IRON, 0.4, 0.7), Vector3(0, rot_y, 0))

static func _mist_plane(parent: Node3D, pos: Vector3, size: Vector2) -> void:
	var mesh := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size = size
	mesh.mesh = plane
	mesh.position = pos
	mesh.rotation_degrees = Vector3(-90, 0, 0)
	var shader := load("res://shaders/fog_mist.gdshader")
	if shader:
		var sm := ShaderMaterial.new()
		sm.shader = shader
		sm.set_shader_parameter("mist_color", Color(0.55, 0.62, 0.78, 1.0))
		sm.set_shader_parameter("speed", 0.04)
		sm.set_shader_parameter("density", 0.4)
		mesh.material_override = sm
	parent.add_child(mesh)

static func _rune(parent: Node3D, pos: Vector3, rot_y: float = 0.0, scale_mul: float = 1.0) -> void:
	var mesh := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size = Vector2(1.4, 1.4) * scale_mul
	mesh.mesh = plane
	mesh.position = pos
	mesh.rotation_degrees = Vector3(-90, rot_y, 0)
	var shader := load("res://shaders/rune_glow.gdshader")
	if shader:
		var sm := ShaderMaterial.new()
		sm.shader = shader
		sm.set_shader_parameter("glow_color", Color(0.5, 0.15, 0.85, 0.85))
		mesh.material_override = sm
	parent.add_child(mesh)

static func _ground_stain(parent: Node3D, pos: Vector3, size: Vector2, rot_y: float = 0.0) -> void:
	var mesh := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size = size
	mesh.mesh = plane
	mesh.position = pos + Vector3(0, 0.02, 0)
	mesh.rotation_degrees = Vector3(-90, rot_y, 0)
	mesh.material_override = _mat(BLOOD, 0.6)
	mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override.albedo_color.a = 0.6
	parent.add_child(mesh)

## Assembles a gothic building from a footprint box + pitched roof + door notch.
static func _building(parent: Node3D, pos: Vector3, footprint: Vector3, rot_y: float = 0.0, wall_color: Color = STONE) -> void:
	var group := Node3D.new()
	group.name = "Building"
	group.position = pos
	group.rotation_degrees = Vector3(0, rot_y, 0)
	parent.add_child(group)
	_box(group, "Walls", footprint, Vector3(0, footprint.y * 0.5, 0), _mat(wall_color, 0.9))
	_cyl(group, "Roof", footprint.z * 0.72, footprint.x * 1.08, Vector3(0, footprint.y + footprint.z * 0.32, 0), _mat(ROOF, 0.75), 3, false, Vector3(0, 0, 90))
	# window glow slits
	for side in [-1.0, 1.0]:
		var win := _box(group, "Window", Vector3(0.06, 0.9, 0.5), Vector3(footprint.x * 0.5 - 0.03, footprint.y * 0.55, side * footprint.z * 0.28), _mat(Color(0.05, 0.04, 0.02), 0.3, 0.0, LANTERN_WARM, 1.4))
		win.use_collision = false

# ---------------------------------------------------------------- zones

static func _build_ground(root: Node3D) -> void:
	# Base ground spans the whole play area; distinct material patches read as
	# separate zones (road dirt / square cobbles / graveyard dead grass).
	_box(root, "GroundRoad", Vector3(40, 0.4, 46), Vector3(0, -0.2, 42), _mat(ROAD_DIRT, 1.0))
	_box(root, "GroundSquare", Vector3(46, 0.4, 46), Vector3(0, -0.2, 6), _mat(STONE_LIGHT, 0.95))
	_box(root, "GroundChurchyard", Vector3(46, 0.4, 26), Vector3(0, -0.2, -22), _mat(STONE, 0.95))
	_box(root, "GroundGraveyard", Vector3(28, 0.4, 34), Vector3(24, -0.22, 0), _mat(GRASS_DEAD, 1.0))
	_box(root, "GroundForestEdge", Vector3(46, 0.4, 24), Vector3(0, -0.24, -48), _mat(Color(0.045, 0.05, 0.045), 1.0))
	_mist_plane(root, Vector3(0, 0.4, 45), Vector2(40, 30))
	_mist_plane(root, Vector3(24, 0.4, 4), Vector2(24, 30))
	_mist_plane(root, Vector3(0, 0.4, -46), Vector2(44, 22))

static func _build_forest_road(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 22:
		var z := 36.0 + rng.randf() * 24.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var x := side * (6.0 + rng.randf() * 16.0)
		_tree(root, Vector3(x, 0, z), 0.85 + rng.randf() * 0.5)
	# broken fencing along the road shoulder
	_fence_run(root, Vector3(-6.5, 0, 58), Vector3(-6.5, 0, 40))
	_fence_run(root, Vector3(6.5, 0, 55), Vector3(6.5, 0, 44))
	# abandoned carriage — assembled from boxes/cylinders, not a single cube
	var cart := Node3D.new()
	cart.name = "AbandonedCarriage"
	cart.position = Vector3(-3.5, 0, 47)
	cart.rotation_degrees = Vector3(0, 18, 0)
	root.add_child(cart)
	_box(cart, "CartBed", Vector3(1.6, 0.6, 2.6), Vector3(0, 0.6, 0), _mat(WOOD, 0.95))
	_box(cart, "CartTilt", Vector3(1.5, 0.05, 2.5), Vector3(0, 0.95, 0), _mat(WOOD, 0.95), Vector3(35, 0, 0))
	for wx in [-0.85, 0.85]:
		for wz in [-0.9, 0.9]:
			_cyl(cart, "Wheel", 0.42, 0.12, Vector3(wx, 0.42, wz), _mat(Color(0.05, 0.03, 0.02), 0.9), 10, false, Vector3(0, 0, 90))
	_ground_stain(root, Vector3(-2.8, 0, 45), Vector2(2.2, 3.4), 20)
	_ground_stain(root, Vector3(-1.0, 0, 42), Vector2(0.6, 2.0), 60)
	# strange marking near the road
	_rune(root, Vector3(2.0, 0.02, 44), 0)
	# old warning sign
	var sign_post := Node3D.new()
	sign_post.position = Vector3(4.0, 0, 52)
	root.add_child(sign_post)
	_box(sign_post, "SignPost", Vector3(0.1, 1.6, 0.1), Vector3(0, 0.8, 0), _mat(WOOD, 1.0))
	_box(sign_post, "SignBoard", Vector3(0.9, 0.5, 0.05), Vector3(0, 1.5, 0), _mat(Color(0.1, 0.08, 0.06), 1.0))

static func _build_gate(root: Node3D) -> void:
	var gate := Node3D.new()
	gate.name = "TownGate"
	gate.position = Vector3(0, 0, 30)
	root.add_child(gate)
	_box(gate, "PillarL", Vector3(1.4, 6.0, 1.4), Vector3(-5, 3.0, 0), _mat(STONE, 0.9))
	_box(gate, "PillarR", Vector3(1.4, 6.0, 1.4), Vector3(5, 3.0, 0), _mat(STONE, 0.9))
	_box(gate, "Lintel", Vector3(11.2, 1.0, 1.4), Vector3(0, 6.5, 0), _mat(STONE_DARK, 0.9))
	for gx in [-2.2, -1.1, 0.0, 1.1, 2.2]:
		_box(gate, "GateBar", Vector3(0.06, 4.6, 0.06), Vector3(gx, 2.5, 0), _mat(IRON, 0.4, 0.7))
	_box(gate, "GateBarTop", Vector3(4.6, 0.06, 0.06), Vector3(0, 4.7, 0), _mat(IRON, 0.4, 0.7))
	_lamp(gate, Vector3(-5, 0, 0.9), LANTERN_WARM, 3.5)
	_lamp(gate, Vector3(5, 0, 0.9), LANTERN_WARM, 3.5)
	# stone wall stretching from the pillars
	_box(gate, "WallL", Vector3(10, 3.2, 1.0), Vector3(-11, 1.6, 0), _mat(STONE, 0.95))
	_box(gate, "WallR", Vector3(10, 3.2, 1.0), Vector3(11, 1.6, 0), _mat(STONE, 0.95))

static func _build_town_square(root: Node3D) -> void:
	var square := Node3D.new()
	square.name = "TownSquare"
	root.add_child(square)
	# fountain
	var fountain := Node3D.new()
	fountain.position = Vector3(0, 0, 14)
	square.add_child(fountain)
	_cyl(fountain, "Basin", 2.6, 0.6, Vector3(0, 0.3, 0), _mat(STONE, 0.8), 12)
	_cyl(fountain, "Pedestal", 0.4, 1.6, Vector3(0, 1.4, 0), _mat(STONE_DARK, 0.8), 8)
	_cyl(fountain, "Bowl", 0.9, 0.35, Vector3(0, 2.2, 0), _mat(STONE, 0.8), 10)
	_lamp(square, Vector3(-3, 0, 12), LANTERN_VIOLET, 2.4)
	_lamp(square, Vector3(3, 0, 16), LANTERN_VIOLET, 2.4)
	# surrounding buildings
	_building(square, Vector3(-15, 0, 10), Vector3(6, 4.2, 6), 12, STONE)
	_building(square, Vector3(15, 0, 8), Vector3(7, 5.0, 6), -14, STONE_LIGHT)
	_building(square, Vector3(-14, 0, -4), Vector3(5.5, 3.8, 5), 4, STONE_DARK)
	_building(square, Vector3(14, 0, -6), Vector3(6.5, 4.6, 6), -6, STONE)
	_building(square, Vector3(-18, 0, 22), Vector3(5, 4.0, 5), 20, STONE)
	_building(square, Vector3(18, 0, 22), Vector3(5, 4.4, 5), -18, STONE_LIGHT)
	_lamp(square, Vector3(-9, 0, 0), LANTERN_WARM, 3.0)
	_lamp(square, Vector3(9, 0, 2), LANTERN_WARM, 3.0)
	_lamp(square, Vector3(0, 0, 24), LANTERN_WARM, 3.0)
	_ground_stain(square, Vector3(4, 0, 5), Vector2(1.4, 2.4), 30)
	_rune(square, Vector3(-6, 0.02, 6), 15)

static func _build_church(root: Node3D) -> Dictionary:
	var church := Node3D.new()
	church.name = "Church"
	church.position = Vector3(0, 0, -18)
	root.add_child(church)
	_box(church, "Nave", Vector3(9, 7.5, 16), Vector3(0, 3.75, 0), _mat(STONE_DARK, 0.85))
	_cyl(church, "NaveRoof", 8.0, 9.2, Vector3(0, 7.5 + 4.0, 0), _mat(ROOF, 0.75), 3, false, Vector3(0, 0, 90))
	_box(church, "Tower", Vector3(3.4, 9.0, 3.4), Vector3(0, 4.5, 8.5), _mat(STONE_DARK, 0.85))
	_cyl(church, "Spire", 2.6, 6.0, Vector3(0, 9.0 + 3.0, 8.5), _mat(STONE, 0.7), 4, true)
	var bell := _cyl(church, "Bell", 0.55, 0.7, Vector3(0, 9.6, 8.5), _mat(Color(0.25, 0.2, 0.1), 0.35, 0.85), 10)
	bell.name = "TowerBell"
	# door
	_box(church, "DoorFrame", Vector3(1.6, 3.2, 0.4), Vector3(0, 1.6, 8.2), _mat(STONE, 0.8))
	_box(church, "Door", Vector3(1.2, 2.8, 0.15), Vector3(0, 1.4, 8.35), _mat(Color(0.08, 0.05, 0.03), 0.9))
	# stained-glass style window glow slits along nave
	for side in [-1.0, 1.0]:
		for i in 3:
			var w := _box(church, "NaveWindow", Vector3(0.08, 2.2, 1.0), Vector3(side * 4.5, 4.2, -5 + i * 4.0), _mat(Color(0.05, 0.04, 0.06), 0.3, 0.0, Color(0.55, 0.3, 0.85), 1.6))
			w.use_collision = false
	_lamp(church, Vector3(-3, 0, 8.6), LANTERN_WARM, 2.6)
	_lamp(church, Vector3(3, 0, 8.6), LANTERN_WARM, 2.6)
	var bell_light := OmniLight3D.new()
	bell_light.position = Vector3(0, 9.6, -18 + 8.5)
	bell_light.light_color = MOON_BLUE
	bell_light.light_energy = 0.0
	bell_light.omni_range = 6.0
	bell_light.name = "BellFlashLight"
	root.add_child(bell_light)
	# interior
	# Interior origin at church center (used by landmarks dict in build())
	_box(church, "AltarBase", Vector3(2.0, 0.9, 1.0), Vector3(0, 0.45, -6.5), _mat(STONE, 0.8))
	for cx in [-0.6, 0.6]:
		var candle := _cyl(church, "Candle", 0.06, 0.5, Vector3(cx, 0.9 + 0.25, -6.5), _mat(Color(0.9, 0.85, 0.7), 0.4))
		candle.use_collision = false
		var cl := OmniLight3D.new()
		cl.position = Vector3(cx, 1.2, -6.5)
		cl.light_color = LANTERN_WARM
		cl.light_energy = 1.4
		cl.omni_range = 4.0
		church.add_child(cl)
	_rune(church, Vector3(0, 0.05, -3.0), 0, 1.6)
	for i in 4:
		_box(church, "PewRow", Vector3(3.0, 0.6, 0.4), Vector3(0, 0.3, -1.5 - i * 1.6), _mat(WOOD, 0.9))
	return {"door": church.position + Vector3(0, 0, 9.5), "interior": church.position + Vector3(0, 1.6, -5)}

static func _build_graveyard(root: Node3D) -> void:
	var yard := Node3D.new()
	yard.name = "Graveyard"
	yard.position = Vector3(24, 0, 0)
	root.add_child(yard)
	var rng := RandomNumberGenerator.new()
	rng.seed = 22
	for i in 26:
		var lx := rng.randf_range(-12, 12)
		var lz := rng.randf_range(-15, 15)
		_tombstone(yard, Vector3(lx, 0, lz), rng.randf_range(-15, 15))
	_fence_run(yard, Vector3(-14, 0, -17), Vector3(14, 0, -17))
	_fence_run(yard, Vector3(-14, 0, 17), Vector3(14, 0, 17))
	_fence_run(yard, Vector3(-14, 0, -17), Vector3(-14, 0, 17))
	_fence_run(yard, Vector3(14, 0, -17), Vector3(14, 0, 17))
	# crypt
	var crypt := Node3D.new()
	crypt.position = Vector3(6, 0, -10)
	crypt.rotation_degrees = Vector3(0, -10, 0)
	yard.add_child(crypt)
	_box(crypt, "CryptBody", Vector3(4.0, 2.6, 4.0), Vector3(0, 1.3, 0), _mat(STONE_DARK, 0.9))
	_cyl(crypt, "CryptRoof", 2.9, 1.6, Vector3(0, 2.6 + 0.5, 0), _mat(ROOF, 0.8), 4, true)
	_box(crypt, "CryptDoor", Vector3(1.0, 1.8, 0.15), Vector3(0, 0.9, 2.05), _mat(Color(0.05, 0.05, 0.05), 0.9))
	for lz in [-8.0, 6.0]:
		_tree(yard, Vector3(-11, 0, lz), 0.7)
	_lamp(yard, Vector3(0, 0, -14), LANTERN_VIOLET, 2.0)
	_lamp(yard, Vector3(0, 0, 14), LANTERN_VIOLET, 2.0)
	_ground_stain(yard, Vector3(3, 0, 4), Vector2(1.6, 1.6), 0)

static func _build_forest_edge(root: Node3D) -> void:
	var edge := Node3D.new()
	edge.name = "ForestEdge"
	edge.position = Vector3(0, 0, -48)
	root.add_child(edge)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 30:
		var x := rng.randf_range(-22, 22)
		var z := rng.randf_range(-10, 10)
		_tree(edge, Vector3(x, 0, z), 1.0 + rng.randf() * 0.7)
	var howl_light := OmniLight3D.new()
	howl_light.position = Vector3(0, 2.5, -6)
	howl_light.light_color = Color(0.65, 0.15, 0.85)
	howl_light.light_energy = 0.6
	howl_light.omni_range = 5.0
	edge.add_child(howl_light)

static func _build_catacomb_entrance(root: Node3D) -> void:
	var cata := Node3D.new()
	cata.name = "CatacombEntrance"
	cata.position = Vector3(34, 0, 14)
	cata.rotation_degrees = Vector3(0, -25, 0)
	root.add_child(cata)
	_box(cata, "StairHousing", Vector3(3.2, 2.0, 3.6), Vector3(0, 1.0, 0), _mat(STONE_DARK, 0.9))
	for i in 6:
		_box(cata, "Step", Vector3(2.4, 0.25, 0.5), Vector3(0, -0.2 - i * 0.3, 0.4 + i * 0.5), _mat(STONE, 0.9))
	_box(cata, "IronGate", Vector3(2.0, 2.0, 0.1), Vector3(0, 1.0, 2.9), _mat(IRON, 0.4, 0.75))
	_rune(cata, Vector3(0, 1.0, 2.95), 0, 1.0)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 0.2, -1.5)
	glow.light_color = Color(0.55, 0.15, 0.85)
	glow.light_energy = 1.2
	glow.omni_range = 3.0
	cata.add_child(glow)
