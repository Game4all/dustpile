// Contains the info for a material

pub const MaterialFlag = enum(u32) {
    /// Static materials are not affected by physics of any kind
    flag_static = 1 << 0,
    /// Solid materials are affected by gravity
    flag_solid = 1 << 1,
    /// Liquid materials are affected by gravity and can flow
    flag_liquid = 1 << 2,
};

pub const MaterialInfo = struct { baseColor: [4]i32, density: f32, flags: MaterialFlag align(8) };

// zig fmt: off
pub const MATERIAL_LIST = [_]MaterialInfo{
    MaterialInfo{ // void
        .baseColor = [_]i32{ 80, 80, 80, 255 },
        .density = 0.0,
        .flags = .flag_static,
    },
    MaterialInfo{ // sand
        .baseColor = [_]i32{ 194, 178, 128, 255 },
        .density = 1.0,
        .flags = .flag_solid,
    },
    MaterialInfo { // wall
        .baseColor = [_]i32{ 120, 120, 120, 120 },
        .density = 1.0,
        .flags = .flag_static,
    },
    MaterialInfo { // dirt
        .baseColor = [_]i32{ 124, 92, 60, 255 },
        .density = 1.0,
        .flags = .flag_solid,
    },
    MaterialInfo { //water
        .baseColor = [_]i32{35, 137, 218, 255 },
        .density = 1.0,
        .flags = .flag_liquid,
    },
    MaterialInfo { // stone
        .baseColor = [_]i32{174, 162 ,149, 255 },
        .density = 8.0,
        .flags = .flag_solid,
    },
    MaterialInfo { // acid
        .baseColor = [_]i32{ 0, 255, 60, 255 },
        .density = 1.0,
        .flags = .flag_solid,
    },
};
