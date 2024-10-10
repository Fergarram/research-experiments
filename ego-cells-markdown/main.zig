const std = @import("std");
const ocl = @import("ocl.zig");
const rl = @import("raylib");
const builtin = @import("builtin");

const assert = std.debug.assert;
const print = std.debug.print;
const ascii = std.ascii;
const mem = std.mem;
const Allocator = mem.Allocator;

pub const io_mode = .evented;

const TokenFeature = enum(u8) {
    EMPTY,
    NONE,
    MONO,
    UNDERLINE,
    BOLD,
    ITALIC,
    STRIKE,
    LINK,
};

const TextType = enum(u8) {
    EMPTY,
    NONE,
    MONO_BORDER,
    MONO_TEXT,
};

const LineType = enum(u8) {
    EMPTY_LINE,
    SNIP_BORDER,
    SNIP_TEXT,
    TEXT,
};

const BlockFeature = enum(u8) {
    EMPTY,
    PARAGRAPH,
    HEADING_1,
    HEADING_2,
    HEADING_3,
    HEADING_4,
    HEADING_5,
    HEADING_6,
    UL_ITEM,
    OL_ITEM,
    SNIP_BLOCK
};

const CharFeature = enum(u8) {
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
    @"__",
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
    outputL2: BlockFeature = undefined,
    outputL3: LineType = undefined,
    outputL4: TextType = undefined,
    outputL5: TokenFeature = undefined,
};

const markdownString = @embedFile("./markdown.md");

// @TODO: Watch file for changes
const cellProgramSource = @embedFile("./program.cl");

var cellMatrix: [128][128]?Cell = undefined;

fn getCellPtr(pos: Point) *?Cell {
    var noone: ?Cell = null;
    if (pos.x < 0 or pos.y < 0) {
        return &noone;
    } else if (pos.x >= 128 or pos.y >= 128) {
        return &noone;
    }
    return &cellMatrix[@intCast(usize, pos.x)][@intCast(usize, pos.y)];
}

fn initializeCellMatrix(matrix: *[128][128]?Cell, markdown: []const u8) void {
    for (matrix.*) |col, x| {
        for (col) |_, y| {
            const xx = @intCast(i32, x);
            const yy = @intCast(i32, y);
            matrix.*[x][y] = Cell{
                .x = xx,
                .y = yy,
                .input = ' ',
                .outputL1 = .@" ",
                .outputL2 = .EMPTY,
                .outputL3 = .EMPTY_LINE,
            };
        }
    }

    {
        var y: i32 = 0;
        var x: i32 = 0;

        for (markdown) |character| {
            if (character == '\n') {
                y += 1;
                x = 0;
                continue;
            }

            var outL1: CharFeature = undefined;

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
            else if (character == '_') outL1 = .@"__"
            else if (character == '>') outL1 = .@">"
            else if (character == '\\') outL1 = .@"\\"
            else outL1 = .@"sym";

            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.input = character;
            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.outputL1 = outL1; 
            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.outputL2 = .EMPTY;
            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.outputL3 = .EMPTY_LINE;
            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.outputL4 = .NONE;

            x += 1;
        }
    }
}

pub fn main() !void {
    initializeCellMatrix(&cellMatrix, markdownString[0..markdownString.len]);

    var cellBuffer3D = [_]u8{0} ** (128*128*5);
    var currentInputVolume: bool = false; // "false" for First and "true" for Second
    var l1Count: usize = 0;

    for (cellMatrix) |col, x| {
        for (col) |_, y| {
            const cellPtr = &cellMatrix[y][x];
            if (cellPtr.* != null) {
                cellBuffer3D[l1Count] = @enumToInt(cellPtr.*.?.outputL1);
            }
            l1Count += 1;
        }
    }

    try ocl.listHardware();

    // const stdin = std.io.getStdIn().reader();
    // var userReadBuff: [10]u8 = undefined;
    var platformNo: usize = 0;
    var deviceNo: usize = 0;

    // print("\nSelect a CL platform: ", .{});
    // if (try stdin.readUntilDelimiterOrEof(userReadBuff[0..], '\n')) |user_input| {
    //     platformNo = try std.fmt.parseInt(usize, user_input, 10);
    // }

    // print("Select a CL device: ", .{});
    // if (try stdin.readUntilDelimiterOrEof(userReadBuff[0..], '\n')) |user_input| {
    //     deviceNo = try std.fmt.parseInt(usize, user_input, 10);
    // }

    // print("\n", .{});

    // {
    //     // assert(std.io.is_async);
    //     // assert(!builtin.single_threaded);

    //     const allocator = std.heap.page_allocator;
        
    //     const sourcePath = try std.fs.path.join(allocator, &[_][]const u8{ "program.cl" });
    //     defer allocator.free(sourcePath);
        
    //     const readContents = try std.fs.cwd().readFileAlloc(allocator, sourcePath, 1024 * 1024);
    //     defer allocator.free(readContents);

    //     // print("{s}\n", .{readContents});

    //     var watch = try std.fs.Watch(void).init(allocator, 0);
    //     defer watch.deinit();

    //     // try watch.addFile(sourcePath, {});

    //     // var ev = async watch.channel.get();
    //     // var ev_consumed = false;
    //     // defer if (!ev_consumed) {
    //     //     _ = await ev;
    //     //     print("We here\n", .{});
    //     // };
    // }

    var device = try ocl.getDeviceId(platformNo, deviceNo);
    print("Selected device ID: {}\n\n", .{device});

    var ctx = try ocl.createContext(&device);
    defer ocl.releaseContext(ctx);

    var commandQueue = try ocl.createCommandQueue(ctx, device);
    defer ocl.releaseCommandQueue(commandQueue);

    var program = try ocl.createProgramWithSource(ctx, cellProgramSource);
    defer ocl.releaseProgram(program);

    try ocl.buildProgramForDevice(program, &device);

    var markdownKernel = try ocl.createKernel(program, "markdown");
    defer ocl.releaseKernel(markdownKernel);

    var imageFormat = ocl.CLImageFormat{
        .order = @enumToInt(ocl.CLChannelOrder.R),
        .type = @enumToInt(ocl.CLChannelType.UNSIGNED_INT8)
    };

    var firstVolume = try ocl.createImage(
        ctx,
        .READ_WRITE,
        imageFormat,
        128,
        128,
        5
    );
    defer ocl.releaseMemObj(firstVolume);

    var secondVolume = try ocl.createImage(
        ctx,
        .READ_WRITE,
        imageFormat,
        128,
        128,
        5
    );
    defer ocl.releaseMemObj(secondVolume);

    // Because this call is "blocking" it means that it will make sure that this "command"
    // will runs ASAP and will wait until it's written.
    // Altarnatively I could use events to make this not blocking.
    try ocl.enqueueWriteImageWithData(
        commandQueue,
        firstVolume,
        true,
        [3]usize{0,0,0},
        [3]usize{128,128,5},
        128 * @sizeOf(u8),
        0,
        u8,
        &cellBuffer3D
    );

    try ocl.setKernelArg(markdownKernel, 0, &firstVolume);
    try ocl.setKernelArg(markdownKernel, 1, &secondVolume);

    // So this will NOT start the command immediately
    try ocl.enqueueNDRangeKernelWithoutEvents(
        commandQueue,
        markdownKernel,
        3,
        [3]usize{128,128,5},
        null
    );

    // This call is blocking until it finishes executing the "command".
    // And if the previous command has not been executed yet, this 
    // forces it to execute and finish. Which in this case the last
    // command was to run the kernel.
    try ocl.enqueueReadImageWithData(
        commandQueue,
        secondVolume,
        true,
        [3]usize{0,0,0},
        [3]usize{128,128,5},
        128 * @sizeOf(u8),
        0,
        u8,
        &cellBuffer3D
    );

    // @TODO: Add an event listener that reacts to changes to the DNA file.
    //        - Set a variable that responds to it i.e. dnaNeedsCompile

    const GRID_SIZE = 6;
    const UIWidth = 300;

    const screenWidth = (128 * GRID_SIZE) + UIWidth;
    const screenHeight = 128 * GRID_SIZE;

    const UIXStart = screenWidth - UIWidth;

    rl.InitWindow(screenWidth, screenHeight, "Ego Cells: Experiment 001");

    rl.SetTargetFPS(60);

    var colCount: c_int = 0;
    var rowCount: c_int = 0;
    var layerCount: c_int = 0;

    var mouseX: c_int = 0;
    var mouseY: c_int = 0;
    var zIndex: c_int = 0;
    var currentCellVal: c_int = -1;
    var currentStep: c_int = 1;
    var totalSteps: c_int = 1;

    // for (cellBuffer3D) |item| {
    //     print("{d}", .{item});
    // }
    // print("\n", .{});

    while (!rl.WindowShouldClose()) {

        mouseX = @divFloor(rl.GetMouseX(), GRID_SIZE);
        mouseY = @divFloor(rl.GetMouseY(), GRID_SIZE);

        if (mouseX <= 0) mouseX = 0;
        if (mouseY <= 0) mouseY = 0;
        if (mouseX >= 127) mouseX = 127;
        if (mouseY >= 127) mouseY = 127;

        if (rl.IsKeyDown(.KEY_RIGHT)) {

            // @TODO: Load new DNA source and compile to kernel
            // @OPTIM: Only compile into kernel if there was a change in the DNA source.
            // if (dnaNeedsCompile) ...
            //     Compile...
            //     dnaNeedsCompile = false;

            // Swap volumes
            var inVolPtr = if (!currentInputVolume) &secondVolume else &firstVolume;
            var outVolPtr = if (!currentInputVolume) &firstVolume else &secondVolume;
            try ocl.setKernelArg(markdownKernel, 0, inVolPtr);
            try ocl.setKernelArg(markdownKernel, 1, outVolPtr);

            // Add program execution to queue
            try ocl.enqueueNDRangeKernelWithoutEvents(
                commandQueue,
                markdownKernel,
                3,
                [3]usize{128,128,5},
                null
            );

            // Read the result when ready
            try ocl.enqueueReadImageWithData(
                commandQueue,
                outVolPtr.*,
                true,
                [3]usize{0,0,0},
                [3]usize{128,128,5},
                128 * @sizeOf(u8),
                0,
                u8,
                &cellBuffer3D
            );

            currentInputVolume = !currentInputVolume;
            currentStep += 1;
        }

        if (rl.IsKeyPressed(.KEY_ONE))   zIndex  = 0;
        if (rl.IsKeyPressed(.KEY_TWO))   zIndex  = 1;
        if (rl.IsKeyPressed(.KEY_THREE)) zIndex  = 2;
        if (rl.IsKeyPressed(.KEY_FOUR))  zIndex  = 3;
        if (rl.IsKeyPressed(.KEY_FIVE))  zIndex  = 4;

        if (rl.IsKeyPressed(.KEY_UP))    zIndex += 1;
        if (rl.IsKeyPressed(.KEY_DOWN))  zIndex -= 1;

        rl.BeginDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.DrawRectangle(UIXStart, 0, UIWidth, screenHeight, rl.GetColor(0x282828FF));
        rl.DrawText(rl.TextFormat("X: %03i", mouseX), (UIXStart) + 8, 8, 20, rl.LIGHTGRAY);
        rl.DrawText(rl.TextFormat("Y: %03i", mouseY), (UIXStart) + 8, 28, 20, rl.LIGHTGRAY);
        rl.DrawText(rl.TextFormat("Z: %03i", zIndex), (UIXStart) + 8, 48, 20, rl.LIGHTGRAY);

        rl.DrawText(
            rl.TextFormat("Step: %i / %i", currentStep, totalSteps),
            (UIXStart) + 8, 78, 20, rl.LIGHTGRAY
        );

        rl.DrawText(
            rl.TextFormat("Val: %i", currentCellVal),
            (UIXStart) + 8, 98, 20, rl.LIGHTGRAY
        );

        var tooltipText: ?[*:0]const u8 = null;
        var cellColor: rl.Color = undefined;

        for (cellBuffer3D) |item| {
            if (zIndex == 0) {
                cellColor = switch (item) {
                    @enumToInt(CharFeature.@"abc"),
                    @enumToInt(CharFeature.@"123"),
                    @enumToInt(CharFeature.@"sym"),
                    @enumToInt(CharFeature.@".") => rl.GetColor(0xC6C6C630),
                    @enumToInt(CharFeature.@">"),
                    @enumToInt(CharFeature.@"#") => rl.GetColor(0xFF0000FF),
                    @enumToInt(CharFeature.@"~"),
                    @enumToInt(CharFeature.@"*"),
                    @enumToInt(CharFeature.@"__"),
                    @enumToInt(CharFeature.@"-") => rl.GetColor(0x008000FF),
                    @enumToInt(CharFeature.@"("),
                    @enumToInt(CharFeature.@")") => rl.GetColor(0xFF8000FF),
                    @enumToInt(CharFeature.@"["),
                    @enumToInt(CharFeature.@"]") => rl.GetColor(0xFFFF00FF),
                    @enumToInt(CharFeature.@"`") => rl.GetColor(0x008080FF),
                    @enumToInt(CharFeature.@"\\") => rl.GetColor(0x0000FFFF),
                    else => rl.GetColor(0x00FF00FF)
                };

            } else if (zIndex == 1) {
                cellColor = switch (item) {
                    // @TODO: Report bug with enums
                    @enumToInt(BlockFeature.PARAGRAPH) => rl.GetColor(0xC6C6C660),
                    @enumToInt(BlockFeature.HEADING_1),
                    @enumToInt(BlockFeature.HEADING_2),
                    @enumToInt(BlockFeature.HEADING_3),
                    @enumToInt(BlockFeature.HEADING_4),
                    @enumToInt(BlockFeature.HEADING_5),
                    @enumToInt(BlockFeature.HEADING_6) => rl.GetColor(0xc40000FF),
                    @enumToInt(BlockFeature.UL_ITEM) => rl.GetColor(0x275ac8FF),
                    @enumToInt(BlockFeature.OL_ITEM) => rl.GetColor(0x275ac8FF),
                    @enumToInt(BlockFeature.SNIP_BLOCK) => rl.GetColor(0xFFFF00FF),
                    else => rl.GetColor(0x00FF00FF)
                };

            } else if (zIndex == 2) {
                cellColor = switch (item) {
                    @enumToInt(LineType.SNIP_BORDER) => rl.GetColor(0xFF00FFFF),
                    @enumToInt(LineType.SNIP_TEXT) => rl.GetColor(0xFFFF00FF),
                    @enumToInt(LineType.TEXT) => rl.GetColor(0xC6C6C630),
                    else => rl.GetColor(0x00FF00FF)
                };

            } else if (zIndex == 3) {
                cellColor = switch (item) {
                    @enumToInt(TextType.NONE) => rl.GetColor(0xC6C6C630),
                    @enumToInt(TextType.MONO_BORDER) => rl.GetColor(0xFF00FFFF),
                    @enumToInt(TextType.MONO_TEXT) => rl.GetColor(0xFFFF00FF),
                    else => rl.GetColor(0x00FF00FF)
                };

            } else if (zIndex == 4) {
                cellColor = switch (item) {
                    @enumToInt(TokenFeature.NONE) => rl.GetColor(0xC6C6C630),
                    @enumToInt(TokenFeature.MONO) => rl.GetColor(0xFF00FFFF),
                    @enumToInt(TokenFeature.UNDERLINE) => rl.GetColor(0xFFFF00FF),
                    @enumToInt(TokenFeature.BOLD) => rl.GetColor(0xc40000FF),
                    @enumToInt(TokenFeature.ITALIC) => rl.GetColor(0x275ac8FF),
                    @enumToInt(TokenFeature.STRIKE) => rl.GetColor(0x00FF00FF),
                    @enumToInt(TokenFeature.LINK) => rl.GetColor(0xFF8000FF),
                    else => rl.GetColor(0x00FF00FF)
                };
            }

            // @IMPROVEMENT: Only draw if it's in viewport
            if (item > 0) {
                rl.DrawCircle(
                    (GRID_SIZE/2) + (colCount * GRID_SIZE),
                    ((GRID_SIZE/2) + (rowCount * GRID_SIZE)) - (zIndex * 128 * GRID_SIZE),
                    GRID_SIZE/3,
                    cellColor
                );
            }

            if (mouseX == colCount and (mouseY + (zIndex * 128)) == rowCount) {
                currentCellVal = @intCast(c_int, item);
                var itemClean = @intCast(u8, item);

                if (zIndex == 0 and item != 0) {
                    var typeName = @intToEnum(CharFeature, itemClean);
                    tooltipText = @tagName(typeName);
                
                } else if (zIndex == 1) {
                    var typeName = @intToEnum(BlockFeature, itemClean);
                    tooltipText = @tagName(typeName);
                
                } else if (zIndex == 2) {
                    var typeName = @intToEnum(LineType, itemClean);
                    tooltipText = @tagName(typeName);
                
                } else if (zIndex == 3) {
                    var typeName = @intToEnum(TextType, itemClean);
                    tooltipText = @tagName(typeName);

                } else if (zIndex == 4) {
                    var typeName = @intToEnum(TokenFeature, itemClean);
                    tooltipText = @tagName(typeName);
                }
            }

            colCount += 1;

            if (colCount == 128) {
                colCount = 0;
                rowCount += 1;
            }

            if (rowCount == 128) {
                layerCount += 1;
            }
        }

        colCount = 0;
        rowCount = 0;
        layerCount = 0;

        if (tooltipText != null) {
            rl.DrawRectangle(
                rl.GetMouseX() + 24,
                rl.GetMouseY(),
                70,
                12,
                rl.WHITE
            );
            rl.DrawText(
                tooltipText.?,
                rl.GetMouseX() + 28,
                rl.GetMouseY(),
                10,
                rl.BLACK
            );
        }

        // rl.DrawFPS(16,16);
        rl.EndDrawing();
    }

    rl.CloseWindow();
}
