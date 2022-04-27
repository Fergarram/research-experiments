const std = @import("std");
const print = std.debug.print;
const ascii = std.ascii;

const Block = enum {
    H1, H2, H3, H4, H5, H6,
    PARAGRAPH,
    // UL_ITEM,
    // OL_ITEM,
    // MONO,
    // UNDERLINE,
    // BOLD,
    // ITALIC,
    // STRIKE,
    // LINK,
    CODE_SNIPPET,
    // QUOTE
};

const LineFeature = enum {
    HEADING,
    SNIP_START,
    SNIP_END,
    SNIP_TEXT,
    TEXT,
    EMPTY_LINE
};


const TokenFeature = enum {
    CONTENT,
    HEAD_SINGLE,
    HEAD_FIRST,
    HEAD_MIDDLE,
    HEAD_LAST,
    SNIP_FIRST,
    SNIP_MIDDLE,
    SNIP_LAST,
    SNIP_LANG,
    SNIP_CONTENT,
    // SNIP_SINGLE,
    // UNDR_START,
    // UNDR_END,
    // BOLD_START,
    // BOLD_END,
    // ITAL_START,
    // ITAL_END,
    // STRK_START,
    // STRK_END,
    // LINK_CONTENT_START,
    // LINK_CONTENT_END,
    // LINK_URL_START,
    // LINK_URL_END,
    // QUOT_START,
    EMPTY
};

const CharFeature = enum {
    @" ",
    @"abc",
    @"123",
    @"sym",
    @".",
    @"#",
    @"~",
    @"-",
    @"(",
    @")",
    @"[",
    @"]",
    @"`",
    @"*",
    @"\\",
    @">"
};

const Point = struct {
    x: i32,
    y: i32,

    pub fn cast(x: usize, y: usize) Point {
        return Point{ .x = @intCast(i32, x), .y = @intCast(i32, y) };
    }
};

const Cell = struct {
    x: i32 = undefined,
    y: i32 = undefined,

    input: u8 = undefined,

    outputL1: CharFeature = undefined,
    outputL2: TokenFeature = undefined,
    outputL3: LineFeature = undefined,
    // outputL4: Block = undefined,

    neighbors: [8]Point = undefined,
    // 0 1 2
    // 7   3
    // 6 5 4
};

const markdownString = @embedFile("./markdown.md");

var cellMatrix: [100][100]?Cell = undefined;

fn getCellPtr(pos: Point) *?Cell {
    var noone: ?Cell = null;
    if (pos.x < 0 or pos.y < 0) {
        return &noone;
    } else if (pos.x >= 100 or pos.y >= 100) {
        return &noone;
    }
    return &cellMatrix[@intCast(usize, pos.x)][@intCast(usize, pos.y)];
}

pub fn main() !void {
    for (cellMatrix) |col, x| {
        for (col) |_, y| {
            const xx = @intCast(i32, x);
            const yy = @intCast(i32, y);
            cellMatrix[x][y] = Cell{
                .x = xx,
                .y = yy,
                .input = ' ',
                .outputL1 = .@" ",
                .outputL2 = .EMPTY,
                .outputL3 = .EMPTY_LINE,
                .neighbors = [8]Point{
                    Point{ .x = xx-1, .y = yy-1 },
                    Point{ .x = xx,   .y = yy-1 },
                    Point{ .x = xx+1, .y = yy-1 },
                    Point{ .x = xx+1, .y = yy },
                    Point{ .x = xx+1, .y = yy+1 },
                    Point{ .x = xx,   .y = yy+1 },
                    Point{ .x = xx-1, .y = yy+1 },
                    Point{ .x = xx-1, .y = yy }
                },
            };
        }
    }

    {
        var y: i32 = 0;
        var x: i32 = 0;

        for (markdownString) |character| {
            if (character == '\n') {
                y += 1;
                x = 0;
                continue;
            }

            var outL1: CharFeature = undefined;

            // NOTE: One could argue that the conditions below should really go in the
            //       cell loop. But, for practical reasons it's better to be here since
            //       this is always static (for now).
            if (ascii.isSpace(character) or ascii.isBlank(character)) outL1 = .@" "
            else if (ascii.isAlpha(character)) outL1 = .@"abc"
            else if (ascii.isDigit(character)) outL1 = .@"123"
            else if (character == '.') outL1 = .@"."
            else if (character == '#') outL1 = .@"#"
            else if (character == '~') outL1 = .@"~"
            else if (character == '-') outL1 = .@"-"
            else if (character == '(') outL1 = .@"("
            else if (character == ')') outL1 = .@")"
            else if (character == '[') outL1 = .@"["
            else if (character == ']') outL1 = .@"]"
            else if (character == '`') outL1 = .@"`"
            else if (character == '*') outL1 = .@"*"
            else if (character == '>') outL1 = .@">"
            else if (character == '\\') outL1 = .@"\\"
            else outL1 = .@"sym";

            cellMatrix[@intCast(usize, x)][@intCast(usize, y)].?.input = character;
            cellMatrix[@intCast(usize, x)][@intCast(usize, y)].?.outputL1 = outL1;
            cellMatrix[@intCast(usize, x)][@intCast(usize, y)].?.outputL2 = .CONTENT;
            cellMatrix[@intCast(usize, x)][@intCast(usize, y)].?.neighbors = [8]Point{
                Point{ .x = x-1, .y = y-1 },
                Point{ .x = x,   .y = y-1 },
                Point{ .x = x+1, .y = y-1 },
                Point{ .x = x+1, .y = y },
                Point{ .x = x+1, .y = y+1 },
                Point{ .x = x,   .y = y+1 },
                Point{ .x = x-1, .y = y+1 },
                Point{ .x = x-1, .y = y }
            };

            x += 1;
        }
    }

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

    print("Cell Size: {d} bytes\n", .{@sizeOf(Cell)});
    const stdin = std.io.getStdIn().reader();

    while (true) {
        var sx: usize = 0;
        var sy: usize = 0;
        var readBuffer: [10]u8 = undefined;

        print("X: ", .{});
        if (try stdin.readUntilDelimiterOrEof(readBuffer[0..], '\n')) |user_input| {
            sx = try std.fmt.parseInt(usize, user_input, 10);
        }

        print("Y: ", .{});
        if (try stdin.readUntilDelimiterOrEof(readBuffer[0..], '\n')) |user_input| {
            sy = try std.fmt.parseInt(usize, user_input, 10);
        }

        const cell: *?Cell = &cellMatrix[sx][sy];

        if (cell.* != null) {
            print("I/O for ({d}, {d}): '{u}' -> L1: '{s}', L2: {s}\n", .{ sx, sy, cell.*.?.input, @tagName(cell.*.?.outputL1), @tagName(cell.*.?.outputL2) });

        } else {
            print("Null cell at ({d}, {d})\n", .{ sx, sy });
        }

        print("\n\n", .{}); 
    }
}
