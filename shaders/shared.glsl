
#define PIXEL_SIZE 4

// globals
layout(std140, binding = 3) uniform globals {
    ivec2 brushPos;
    float brushSize;
    int currentMaterial;
    int inputState;
    float time;
};
