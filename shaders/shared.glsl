
#define PIXEL_SIZE 4

// materials
#define MAT_ID_AIR 0
#define MAT_ID_SAND 1
#define MAT_ID_WALL 2
#define MAT_ID_DIRT 3
#define MAT_ID_WATER 4
#define MAT_ID_STONE 5
#define MAT_ID_ACID 6
#define MAT_ID_MOSS 7


// brush types
#define BRUSH_TYPE_CIRCLE 0
#define BRUSH_TYPE_SQUARE 1
#define BRUSH_TYPE_HLINE 2

// globals
layout(std140, binding = 3) uniform globals {
    ivec2 BrushPos;
    float BrushSize;
    int BrushType;
    int CurrentMaterial;
    int inputState;
    float Time;
    int SimRunning;
};

struct MaterialInfo {
    /// Base color of the material in RGBA integer format
    ivec4 BaseColor;
    float Density;
    int Flags;
};


layout(std140, binding = 4) uniform materials {
    MaterialInfo Materials[8];
};

MaterialInfo GetMaterialInfo(int id) {
    return Materials[id];
}

// returns a random float between 0 and 1
float Random(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// returns a random direction offset of 1 or -1
int RandomDir(vec2 co) { 
    return Random(co) > 0.5 ? 1 : -1;
}

vec4 GetMaterialColor(ivec2 pos, ivec4 cell) {
    const MaterialInfo info = GetMaterialInfo(cell.r);
    switch (cell.r) {
        case MAT_ID_DIRT:
            switch (cell.g) {
                case 1:
                    return vec4(65., 152., 10., 255.) / 255. + Random(vec2(cell.w)) * 0.2121;

                case 2:
                    return vec4(0., 102., 10., 255.) / 255. + Random(vec2(cell.w)) * 0.2121;

                default:
                    return vec4(info.BaseColor) / 255. + Random(vec2(cell.w)) * 0.2121;
            }
        break;

        case MAT_ID_WATER:
            return vec4(info.BaseColor) / 255. + 0.2121;
        break;

        default:
            return vec4(info.BaseColor) / 255. + Random(vec2(cell.w)) * 0.2121;
    }
}



/// SDF functions for the brush
bool Brush(ivec2 pos, float size) {
    switch (BrushType) {
        case BRUSH_TYPE_CIRCLE:
            return length(pos) - size * PIXEL_SIZE < 0.;

        case BRUSH_TYPE_SQUARE: 
        {
            const vec2 cords = ivec2(size * PIXEL_SIZE);
            vec2 d = abs(pos) - cords;
            return length(max(d,0.0)) + min(max(d.x,d.y),0.0) < 0.;
        }

        case BRUSH_TYPE_HLINE: {
            const vec2 cords = ivec2(size * PIXEL_SIZE, size * PIXEL_SIZE / 4);
            vec2 d = abs(pos) - cords;
            return length(max(d,0.0)) + min(max(d.x,d.y),0.0) < 0.;
        }
    }
}