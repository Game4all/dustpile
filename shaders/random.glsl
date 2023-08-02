

// returns a random float between 0 and 1
float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// returns a random direction offset of 1 or -1
int randomDir(vec2 co) { 
    return rand(co) > 0.5 ? 1 : -1;
}