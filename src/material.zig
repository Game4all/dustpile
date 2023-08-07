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
pub const MATERIAL_LIST: [3]MaterialInfo = [_]MaterialInfo{
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
};
