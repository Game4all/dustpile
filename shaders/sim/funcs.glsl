
// Returns the cell at the given position, or a cell with r = 255 if the position is out of bounds
ivec4 GetCell(ivec2 pos) {
    const ivec2 resolution = imageSize(World) / PIXEL_SIZE;
    if (pos.x < 0 || pos.x >= resolution.x || pos.y < 0 || pos.y >= resolution.y)
        return ivec4(MAT_ID_WALL, 0, 0, 0);
    else
        return imageLoad(World, pos);
}

/// Swaps the contents of two cells
void SwapCells(ivec2 src, ivec4 srcCell, ivec2 dst, ivec4 dstCell) {
    imageStore(FutureWorld, dst, srcCell);
    imageStore(FutureWorld, src, dstCell);
}

bool SimulateSolidCell(ivec2 pos, ivec4 cellValue) {
    ivec2 underCellPos = pos + ivec2(0, -1);
    ivec4 underCell = GetCell(underCellPos);

    // swap with under cell if it's empty
    if (underCell.r == 0) {
        SwapCells(pos, cellValue, underCellPos, underCell);
        return true;
    }

    // swap with under right or left cell if it's empty
    ivec2 randomSideCell = ivec2(pos) + ivec2(randomDir(vec2(pos) + Time), -1);
    ivec4 sideCell = GetCell(randomSideCell);

    if (sideCell.r == 0) {
        SwapCells(pos, cellValue, randomSideCell, sideCell);
        return true;
    }

    return false;
}