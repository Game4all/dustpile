// Contains the info for a material

pub const MaterialFlag = enum(u32) {
    /// Static materials are not affected by physics of any kind
    flag_static = 1 << 0,
    /// Solid materials are affected by gravity
    flag_solid = 1 << 1,
    /// Liquid materials are affected by gravity and can flow
    flag_liquid = 1 << 2,
};

pub const MaterialInfo = struct { baseColor: [4]f32, density: f32, flags: MaterialFlag align(8) };

pub const MATERIAL_LIST: [2]MaterialInfo = [_]MaterialInfo{
    MaterialInfo{
        .baseColor = [_]f32{ 0.2, 0.2, 0.2, 1.0 },
        .density = 0.0,
        .flags = .flag_static,
    },
    MaterialInfo{
        .baseColor = [_]f32{ 194.0 / 255.0, 178.0 / 255.0, 128.0 / 255.0, 1.0 },
        .density = 1.0,
        .flags = .flag_solid,
    },
};
