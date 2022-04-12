const std = @import("std");
const print = std.debug.print;
const ascii = std.ascii;

const Block = enum {
    H1, H2, H3, H4, H5, H6,
    PARAGRAPH,
    UL_ITEM,
    OL_ITEM,
    MONO,
    UNDERLINE,
    BOLD,
    ITALIC,
    STRIKE,
    LINK,
    CODE_SNIPPET,
    QUOTE,
    // NOTE: Tables are not part of MD but would be interesting
    //       https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#tables
};

const Tokens = enum {
    HEADING_START,
    MONO_TICK,
    UNDERLINE_START,
    UNDERLINE_END,
    BOLD_START,
    BOLD_END,
    ITALIC_START,
    ITALIC_END,
    STRIKE_START,
    STRIKE_END,
    LINK_CONTENT_START,
    LINK_CONTENT_END,
    LINK_URL_START,
    LINK_URL_END,
    SNIPPET_START,
    SNIPPET_END,
    SNIPPET_CONTENT,
    QUOTE_START,
    CONTENT,
    UNKOWN
};

const Point = struct {
    x: i32,
    y: i32,

    pub fn cast(x: usize, y: usize) Point {
        return Point{ .x = @intCast(i32, x), .y = @intCast(i32, y) };
    }
};

const Cell = struct {
    x: i32,
    y: i32,

    input: u8 = undefined,

    output: Tokens = .UNKOWN,

    // 0 1 2
    // 7   3
    // 6 5 4
    // Each represent a position relative to the buffer.
    neighbors: [8]Point,
};

const markdownString = @embedFile("./markdown.md");

// @TODO: No longer need a limited cell matrix like this one.
var cellMatrix: [100][100]?Cell = undefined;

fn getCellPtr(pos: Point) *?Cell {
    if (pos.x < 0 or pos.y < 0) {
        var r: ?Cell = null;
        return &r;
    }
    return &cellMatrix[@intCast(usize, pos.x)][@intCast(usize, pos.y)];
}

pub fn main() !void {
    var cellPtrList = std.ArrayList(*?Cell).init(std.testing.allocator);
    defer cellPtrList.deinit();

    {
        var y: i32 = 0;
        var x: i32 = 0;

        for (markdownString) |character| {
            if (character == '\n') {
                y += 1;
                x = 0;
                continue;
            }

            cellMatrix[@intCast(usize, x)][@intCast(usize, y)] = Cell{
                .x = x,
                .y = y,
                .input = character,
                .neighbors = [8]Point{
                    Point{ .x = x-1, .y = y-1 },
                    Point{ .x = x,   .y = y-1 },
                    Point{ .x = x+1, .y = y-1 },
                    Point{ .x = x+1, .y = y },
                    Point{ .x = x+1, .y = y+1 },
                    Point{ .x = x,   .y = y+1 },
                    Point{ .x = x-1, .y = y+1 },
                    Point{ .x = x-1, .y = y }
                },
            };

            try cellPtrList.append(&cellMatrix[@intCast(usize, x)][@intCast(usize, y)]);

            x += 1;
        }
    }

    print("Cell Size: {d} bytes\n", .{@sizeOf(Cell)});

    // This loop is a single step
    // For each powered cell, we run their activation code to pass on to the next layer on top.
    for (cellPtrList.items) |cellPtr| {
        if (cellPtr.* != null) {
            // const topleft = getCellPtr(cellPtr.*.?.neighbors[0]);
            // const top = getCellPtr(cellPtr.*.?.neighbors[1]);
            // const topright = getCellPtr(cellPtr.*.?.neighbors[2]);
            const right = getCellPtr(cellPtr.*.?.neighbors[3]);
            // const bottomright = getCellPtr(cellPtr.*.?.neighbors[4]);
            // const bottom = getCellPtr(cellPtr.*.?.neighbors[5]);
            // const bottomleft = getCellPtr(cellPtr.*.?.neighbors[6]);
            const left = getCellPtr(cellPtr.*.?.neighbors[7]);

            // '#', '-', '~', '[', ']', '>', '`', '(', ')', ' ', '!', '*', '_', '0..9', '.'

            // HEADING_START
            if (
                cellPtr.*.?.input == '#' and
                (left.* == null or left.*.?.input == '#') and
                (right.*.?.input == '#' or right.*.?.input == ' ')
            ) {
                // print("HEADING_START\n", .{});
                cellPtr.*.?.output = .HEADING_START;
            }

            // SNIPPET_START
            if (
                cellPtr.*.?.input == '`' and
                (left.* == null or left.*.?.input == '`') and
                (
                    right.* == null or
                    right.*.?.input == '`' or
                    right.*.?.input == ' ' or
                    ascii.isAlNum(right.*.?.input)
                )
            ) {
                // print("SNIPPET_START\n", .{});
                cellPtr.*.?.output = .SNIPPET_START;
            }
        }
    }

    // @TODO: Export a JSON file with the state of each cell so that I can analyze it and visualize it in each generation or step.
    
    // Extra points: Create a websocket endpoint that serves this JSON: 
    // developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers


    //
    // Loop to query each cell in terminal
    //

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
            print("I/O for ({d}, {d}): '{u}' -> {s}\n", .{ sx, sy, cell.*.?.input, @tagName(cell.*.?.output) });

        } else {
            print("Null cell at ({d}, {d})\n", .{ sx, sy });
        }

        print("\n\n", .{}); 
    }
}
