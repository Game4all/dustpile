pub const MaterialInfo = struct {
    baseColor: [4]i32,
    density: f32 align(16),
};

// zig fmt: off
pub const MATERIAL_LIST = [_]MaterialInfo{
    MaterialInfo{ // void
        .baseColor = [_]i32{ 80, 80, 80, 255 },
        .density = 0.0,
    },
    MaterialInfo{ // sand
        .baseColor = [_]i32{ 194, 178, 128, 255 },
        .density = 1.0,
    },
    MaterialInfo { // wall
        .baseColor = [_]i32{ 120, 120, 120, 120 },
        .density = 1.0,
    },
    MaterialInfo { // dirt
        .baseColor = [_]i32{ 124, 92, 60, 255 },
        .density = 1.0,
    },
    MaterialInfo { //water
        .baseColor = [_]i32{35, 137, 218, 255 },
        .density = 1.0,
    },
    MaterialInfo { // stone
        .baseColor = [_]i32{174, 162 ,149, 255 },
        .density = 8.0,
    },
    MaterialInfo { // acid
        .baseColor = [_]i32{ 0, 255, 60, 255 },
        .density = 1.0,
    },
    MaterialInfo { // moss
        .baseColor = [_]i32{ 0, 100, 0, 255 },
        .density = 1.0,
    },
    MaterialInfo { // lava
        .baseColor = [_]i32{255, 128, 0, 255},
        .density = 1.0,
    }
};
