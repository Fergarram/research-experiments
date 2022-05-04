    for (cellMatrix) |col, x| {
        for (col) |_, y| {
            const cellPtr = &cellMatrix[x][y];
            if (cellPtr.* != null) {
                // const topleft = getCellPtr(cellPtr.*.?.neighbors[0]);
                const top = getCellPtr(cellPtr.*.?.neighbors[1]);
                // const topright = getCellPtr(cellPtr.*.?.neighbors[2]);
                const right = getCellPtr(cellPtr.*.?.neighbors[3]);
                // const bottomright = getCellPtr(cellPtr.*.?.neighbors[4]);
                const bottom = getCellPtr(cellPtr.*.?.neighbors[5]);
                // const bottomleft = getCellPtr(cellPtr.*.?.neighbors[6]);
                const left = getCellPtr(cellPtr.*.?.neighbors[7]);

                if (cellPtr.*.?.outputL1 == .@"#") {
                    // HEAD_SINGLE
                    if (
                        left.* == null and
                        (right.* != null and right.*.?.outputL1 == .@" ")
                    ) {
                        cellPtr.*.?.outputL2 = .HEAD_SINGLE;
                    }

                    // HEAD_FIRST
                    if (
                        left.* == null and
                        (right.* != null and right.*.?.outputL1 == .@"#")
                    ) {
                        cellPtr.*.?.outputL2 = .HEAD_FIRST;
                    }

                    // HEAD_MIDDLE
                    if (
                        (left.* != null and left.*.?.outputL1 == .@"#") and
                        (left.* != null and left.*.?.outputL2 == .HEAD_FIRST) and
                        (right.* != null and right.*.?.outputL1 == .@"#") and
                        (right.* != null and right.*.?.outputL2 == .HEAD_LAST)
                    ) {
                        cellPtr.*.?.outputL2 = .HEAD_MIDDLE;
                    }

                    // HEAD_LAST
                    if (
                        (left.* != null and left.*.?.outputL1 == .@"#") and
                        (right.* != null and right.*.?.outputL1 == .@" ")
                    ) {
                        cellPtr.*.?.outputL2 = .HEAD_LAST;
                    }
                }

                if (cellPtr.*.?.outputL1 == .@"`") {
                    // SNIP_FIRST
                    if (
                        left.* == null and
                        (right.* != null and right.*.?.outputL1 == .@"`")
                    ) {
                        cellPtr.*.?.outputL2 = .SNIP_FIRST;
                    }

                    // SNIP_MIDDLE
                    if (
                        (left.* != null and left.*.?.outputL1 == .@"`") and
                        (left.* != null and left.*.?.outputL2 == .SNIP_FIRST) and
                        (right.* != null and right.*.?.outputL1 == .@"`") and
                        (right.* != null and right.*.?.outputL2 == .SNIP_LAST)
                    ) {
                        cellPtr.*.?.outputL2 = .SNIP_MIDDLE;
                    }

                    // SNIP_LAST
                    if (
                        (left.* != null and left.*.?.outputL1 == .@"`") and
                        (right.* == null or right.*.?.outputL1 == .@"abc")
                    ) {
                        cellPtr.*.?.outputL2 = .SNIP_LAST;
                    }
                }

                if (
                    cellPtr.*.?.outputL2 == .EMPTY and
                    (bottom.* != null and bottom.*.?.outputL2 == .SNIP_CONTENT) and
                    (
                        left.* != null and
                        (left.*.?.outputL2 == .SNIP_LAST or left.*.?.outputL2 == .SNIP_LANG)
                    )
                ) {
                    cellPtr.*.?.outputL3 = .SNIP_START;
                }

                if (
                    cellPtr.*.?.outputL2 == .EMPTY and
                    (top.* != null and top.*.?.outputL2 == .SNIP_CONTENT) and
                    (left.* != null and left.*.?.outputL2 == .SNIP_LAST)
                ) {
                    cellPtr.*.?.outputL3 = .SNIP_END;
                }

                if (
                    top.* != null and
                    (
                        top.*.?.outputL2 == .SNIP_FIRST or
                        top.*.?.outputL2 == .SNIP_MIDDLE or
                        top.*.?.outputL2 == .SNIP_LAST or
                        top.*.?.outputL2 == .SNIP_LANG
                    )
                ) {
                    // THIS ALWAYS OVERRIDES
                    cellPtr.*.?.outputL2 = .SNIP_CONTENT;
                }

                if (cellPtr.*.?.outputL2 == .EMPTY and
                    bottom.* != null and
                    (
                        bottom.*.?.outputL2 == .SNIP_FIRST or
                        bottom.*.?.outputL2 == .SNIP_MIDDLE or
                        bottom.*.?.outputL2 == .SNIP_LAST
                    ) and
                    top.* != null and
                    (
                        top.*.?.outputL2 == .SNIP_CONTENT
                    )
                ) {
                    // THIS ALWAYS OVERRIDES EMPTY SPACES
                    cellPtr.*.?.outputL2 = .SNIP_CONTENT;
                }

                if (
                    cellPtr.*.?.outputL3 != .SNIP_START and
                    cellPtr.*.?.outputL3 != .SNIP_END and 
                    (
                        (top.* != null and top.*.?.outputL2 == .SNIP_CONTENT) or
                        (left.* != null and left.*.?.outputL2 == .SNIP_CONTENT) or
                        (right.* != null and right.*.?.outputL2 == .SNIP_CONTENT) or
                        (bottom.* != null and bottom.*.?.outputL2 == .SNIP_CONTENT)
                    )
                ) {
                    cellPtr.*.?.outputL2 = .SNIP_CONTENT;
                }
            }
        }
    }