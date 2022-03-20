//   ABCDEFGHIJKLMNOP //
// A ---------------- //
// B # Title--------- //
// C ---------------- //
// D Paragraph text-- //
// E ---------------- //

// In this grid most cells are unactivated or represent an empty cell but there are a few that have been given single values.

// Each cell can access their neighbors and based on that they can assume an identity, in the case of cell AB it's 100% certain it's a '#' character and it would be X% sure that it's part of a "heading 1" bigger holon because this cell has knowledge about what it can be a part of and what it takes to be a part of such a bigger holon based on its vision of its neighbors' value and (maybe) their assumptions about what they can be in the bigger scope.

// There might be a need for a second or more layers of cells that help with the bigger scopes. This might be needed for parallelism — supervision of a range of cells might execute faster when in parallel or it simply might not be possible otherwise.

// Maybe the first layer is static and thus it feels weird to only have "one" layer of cells but in reality it's two but one is static because the value is a static character.

// So what I need to do is create a representation of an ego cell.

// So, something like a dynamic "union" type that can become a value of 0 - 100% of an identity.

// The tendency to identify with a block will be defined by each cell's neighbors. 

const std = @import("std");
const print = std.debug.print;

// All in-line blocks are full-line blocks but not all full-line blocks are in-line blocks.
const Block = enum {
    H1, H2, H3, H4, H5, H6, // full-line 
    PARAGRAPH, // full-line
    UL_ITEM, // full-line
    OL_ITEM, // full-line
    MONO, // in-line
    UNDERLINE, // in-line
    BOLD, // in-line
    ITALIC, // in-line
    STRIKE, // in-line
    LINK, // in-line
    CODE_SNIPPET, // multi-line
    BLOCKQUOTE, // multi-line

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

    value: ?u8 = null,

    // For each Block type a cell can have a % of identification with being part of the block. The order of the items in the array represents the block type, so the first item would point to the H1 block.
    tendencies: [@typeInfo(Block).Enum.fields.len] f16 = undefined,

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
            // Rules for being a '#':
            // 1. If I'm a '#' and I'm at the beginning, I could be a heading start.
            // 2. If my right neighbor is a space, I am a heading 1 start.
            // 3. If my right neighbor is a '#', I could be any heading start except 
            //    a heading 1 start.
            // 4. If my neighbors think they are part of a heading, then it reasurres
            //    me that I'm a heading as well.

            // NOTES:
            // * How much does it increase in activation which each rule?
            // * Could it be that the amounts of rules and their conclusions define 
            //   the amount of activation it will have?
            // * How do rules cancel each other out?

            print("{u}", .{cellPtr.*.?.value});
        }
    }

    // @TODO: Export a JSON file with the state of each cell so that I can analyze it and visualize it. Extra points: Create a REST endpoint that serves this JSON.

    // const sx: usize = 14;
    // const sy: usize = 3;

    // const cell: *?Cell = &cellMatrix[sx][sy];

    // if (cell.* != null) {
    //     print("Character for cell in ({d}, {d}): '{u}'\n", .{ sx, sy, cell.*.?.value });

    //     const neighborCell: *?Cell = getCellPtr(cell.*.?.neighbors[3]);
    //     if (neighborCell.*) |n| {
    //         print("Right neighbor character: '{u}'\n", .{n.value});
    //     } else {
    //         print("Right neighbor character: null\n", .{});
    //     }

    // } else {
    //     print("Character for cell in ({d}, {d}): null\n", .{ sx, sy });
    // }
}
