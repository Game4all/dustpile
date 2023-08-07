
// Returns the cell at the given position, or a cell with r = 255 if the position is out of bounds
ivec4 GetCell(ivec2 pos) {
    const ivec2 resolution = imageSize(World) / PIXEL_SIZE;
    if (pos.x < 0 || pos.x >= resolution.x || pos.y < 0 || pos.y >= resolution.y)
        return ivec4(255, 0, 0, 0);
    else
        return imageLoad(World, pos);
}

/// Swaps the contents of two cells
void SwapCells(ivec2 src, ivec4 srcCell, ivec2 dst, ivec4 dstCell) {
    imageStore(FutureWorld, dst, srcCell);
    imageStore(FutureWorld, src, dstCell);
}

// Solids fall down, and if they can't, they move sideways
void SimSolid(ivec2 src, ivec4 cell) {
    ivec4 bottomCell = GetCell(ivec2(src) - ivec2(0, 1));
    if  (bottomCell.r == 0) 
    {
        SwapCells(ivec2(src), cell, ivec2(src) - ivec2(0, 1), bottomCell);
        return;
    }

    ivec2 randomSideCell = ivec2(src) + ivec2(randomDir(vec2(src) + Time), -1);
    ivec4 sideCell = GetCell(randomSideCell);

    if (sideCell.r == 0) 
    {
        SwapCells(ivec2(src), cell, randomSideCell, sideCell);
        return;
    }

    imageStore(FutureWorld, src, cell);
}