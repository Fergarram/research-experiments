const std = @import("std");
const print = std.debug.print;

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
    BLOCKQUOTE,
    // NOTE: Tables are not part of MD but would be interesting
    //       https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#tables
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

    value: u8 = undefined,

    // For each Block type a cell can have a % of identification with being part of the block. The order of the items in the array represents the block type, so the first item would point to the H1 block.
    tendencies: [@typeInfo(Block).Enum.fields.len] f16 = [_]f16{0} ** @typeInfo(Block).Enum.fields.len,

    // 0 1 2
    // 7   3
    // 6 5 4
    // Each represent a position relative to the buffer.
    neighbors: [8]Point,
};

const markdownString = @embedFile("./markdown.md");

var cellMatrix: [100][100]?Cell = undefined;

fn getCellPtr(pos: Point) *?Cell {
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
                .value = character,
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
    print("Potential Size: {} KB\n\n", .{(10000 * @sizeOf(Cell)) / 1024});

    for (cellPtrList.items) |cellPtr| {
        if (cellPtr.* != null) {
            const topleft = getCellPtr(cellPtr.*.?.neighbors[0]);
            const top = getCellPtr(cellPtr.*.?.neighbors[1]);
            const topright = getCellPtr(cellPtr.*.?.neighbors[2]);
            const right = getCellPtr(cellPtr.*.?.neighbors[3]);
            const bottomright = getCellPtr(cellPtr.*.?.neighbors[4]);
            const bottom = getCellPtr(cellPtr.*.?.neighbors[5]);
            const bottomleft = getCellPtr(cellPtr.*.?.neighbors[6]);
            const left = getCellPtr(cellPtr.*.?.neighbors[7]);

            // Rules for being a '#':
            // 1. If I'm a '#' and I'm at the beginning, I could be a heading start.
            // 2. If my right neighbor is a space, I am a heading 1 start.
            // 3. If my right neighbor is a '#', I could be any heading start except 
            //    a heading 1 start.
            // 4. If my neighbors think they are part of a heading, then it reasurres
            //    me that I'm a heading as well.

            // NOTES:
            // * How much does it increase in activation with each rule?
            // * Could it be that the amount of rules and their conclusions define 
            //   the amount of activation it will have?
            // * How do rules cancel each other out?
            // * Can there be an algorithm that defines the amount of activation a set of 
            //   rules would result in?

            if (cellPtr.*.?.value == '#') {
                cellPtr.*.?.tendencies[0] = 0.25;
                cellPtr.*.?.tendencies[1] = 0.25;
                cellPtr.*.?.tendencies[2] = 0.25;
                cellPtr.*.?.tendencies[3] = 0.25;
                cellPtr.*.?.tendencies[4] = 0.25;
                cellPtr.*.?.tendencies[5] = 0.25;
            }

            if (right.* != null and right.*.?.value == ' ') {
                cellPtr.*.?.tendencies[0] = 0.9;
                cellPtr.*.?.tendencies[1] = 0;
                cellPtr.*.?.tendencies[2] = 0;
                cellPtr.*.?.tendencies[3] = 0;
                cellPtr.*.?.tendencies[4] = 0;
                cellPtr.*.?.tendencies[5] = 0;
            }
        }

        // @TODO: Export a JSON file with the state of each cell so that I can analyze it and visualize it in each generation or step.
    
        // Extra points: Create a websocket endpoint that serves this JSON: 
        // developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers
    }

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
            print("Value for ({d}, {d}): '{u}'\n", .{ sx, sy, cell.*.?.value });
            for (cell.*.?.tendencies) |tendency, index| {
                print("Tendency[{}]: {d:.3}\n", .{ index, tendency});
            }

        } else {
            print("Null cell at ({d}, {d})\n", .{ sx, sy });
        }

        print("\n\n", .{}); 
    }
}
