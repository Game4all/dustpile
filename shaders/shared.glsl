
#define PIXEL_SIZE 4

// globals
layout(std140, binding = 3) uniform globals {
    ivec2 brushPos;
    float brushSize;
    int currentMaterial;
    int inputState;
    float time;
};

struct MaterialInfo {
    vec4 baseColor;
    float density;
    int flags;
};

layout(std140, binding = 4) uniform materialInfo {
    MaterialInfo materials[2];
};