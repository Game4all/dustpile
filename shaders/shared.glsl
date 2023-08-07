
#define PIXEL_SIZE 4

// materials
#define MAT_ID_AIR 0


// brush types
#define BRUSH_TYPE_CIRCLE 0
#define BRUSH_TYPE_SQUARE 1


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
    vec4 BaseColor;
    float Density;
    int Flags;
};

layout(std140, binding = 4) uniform materials {
    MaterialInfo Materials[2];
};

// returns a random float between 0 and 1
float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// returns a random direction offset of 1 or -1
int randomDir(vec2 co) { 
    return rand(co) > 0.5 ? 1 : -1;
}

/// SDF functions for the brush
bool Brush(ivec2 pos, float size) {
    switch (BrushType) {
        case BRUSH_TYPE_CIRCLE:
            return length(pos) - size * PIXEL_SIZE < 0.;
        default:
        case BRUSH_TYPE_SQUARE: 
        {
            const vec2 cords = ivec2(size * PIXEL_SIZE);
            vec2 d = abs(pos) - cords;
            return length(max(d,0.0)) + min(max(d.x,d.y),0.0) < 0.;
        }
    }
}