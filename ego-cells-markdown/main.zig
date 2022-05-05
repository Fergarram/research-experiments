const std = @import("std");
const ocl = @import("ocl.zig");
const rl = @import("raylib");

const print = std.debug.print;
const ascii = std.ascii;

const Block = enum(u8) {
    NONE,
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
    QUOTE
};

const LineFeature = enum(u8) {
    EMPTY_LINE,
    HEADING,
    SNIP_BEGIN,
    SNIP_END,
    SNIP_TEXT,
    TEXT,
};


const TokenFeature = enum(u8) {
    EMPTY,
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
    SNIP_SINGLE,
    UNDR_START,
    UNDR_END,
    BOLD_START,
    BOLD_END,
    ITAL_START,
    ITAL_END,
    STRK_START,
    STRK_END,
    LINK_CONTENT_START,
    LINK_CONTENT_END,
    LINK_URL_START,
    LINK_URL_END,
    QUOT_START
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
    outputL4: Block = undefined,
};

const markdownString = @embedFile("./markdown.md");
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

            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.input = character;
            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.outputL1 = outL1;
            matrix.*[@intCast(usize, x)][@intCast(usize, y)].?.outputL2 = .CONTENT;
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

    var device = try ocl.getDeviceId(platformNo, deviceNo);
    print("Selected device ID: {}\n\n", .{device});

    var ctx = try ocl.createContext(&device);
    defer ocl.releaseContext(ctx);

    var commandQueue = try ocl.createCommandQueue(ctx, device);
    defer ocl.releaseCommandQueue(commandQueue);

    var program = try ocl.createProgramWithSource(ctx, cellProgramSource);
    defer ocl.releaseProgram(program);

    try ocl.buildProgramForDevice(program, &device);

    var kernel = try ocl.createKernel(program, "markdown");
    defer ocl.releaseKernel(kernel);

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

    try ocl.setKernelArg(kernel, 0, &firstVolume);
    try ocl.setKernelArg(kernel, 1, &secondVolume);

    // So this will NOT start the command immediately
    try ocl.enqueueNDRangeKernelWithoutEvents(
        commandQueue,
        kernel,
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

        if (rl.IsKeyPressed(.KEY_RIGHT)) {
            // Swap volumes
            var inVolPtr = if (!currentInputVolume) &secondVolume else &firstVolume;
            var outVolPtr = if (!currentInputVolume) &firstVolume else &secondVolume;
            try ocl.setKernelArg(kernel, 0, inVolPtr);
            try ocl.setKernelArg(kernel, 1, outVolPtr);

            // Add program execution to queue
            try ocl.enqueueNDRangeKernelWithoutEvents(
                commandQueue,
                kernel,
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

        if (rl.IsKeyPressed(.KEY_ONE)) zIndex = 0;
        if (rl.IsKeyPressed(.KEY_TWO)) zIndex = 1;
        if (rl.IsKeyPressed(.KEY_THREE)) zIndex = 2;
        if (rl.IsKeyPressed(.KEY_FOUR)) zIndex = 3;
        if (rl.IsKeyPressed(.KEY_FIVE)) zIndex = 4;
        if (rl.IsKeyPressed(.KEY_UP)) zIndex += 1;
        if (rl.IsKeyPressed(.KEY_DOWN)) zIndex -= 1;

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
                cellColor = switch (@intToEnum(CharFeature, item)) {
                    .@"abc", .@"123", .@"sym", .@"." => rl.GetColor(0xC6C6C6FF),
                    .@">",
                    .@"#" => rl.GetColor(0xFF0000FF),
                    .@"~",
                    .@"*",
                    .@"-" => rl.GetColor(0x008000FF),
                    .@"(",
                    .@")",
                    .@"[",
                    .@"]" => rl.GetColor(0xFFFF00FF),
                    .@"`" => rl.GetColor(0x008080FF),
                    .@"\\" => rl.GetColor(0x0000FFFF),
                    else => rl.GetColor(0x00FF00FF)
                };
            } else if (zIndex == 1) {
                cellColor = switch (@intToEnum(TokenFeature, item)) {
                    .CONTENT => rl.GetColor(0xC6C6C630),
                    .SNIP_CONTENT => rl.GetColor(0xae523fFF),
                    .SNIP_LANG => rl.GetColor(0xFFFF00FF),
                    .SNIP_FIRST => rl.GetColor(0xc40000FF),
                    .SNIP_MIDDLE => rl.GetColor(0xe20057FF),
                    .SNIP_LAST => rl.GetColor(0xff00aeFF),
                    .HEAD_SINGLE => rl.GetColor(0x60ffdfFF),
                    .HEAD_FIRST => rl.GetColor(0x44acd3FF),
                    .HEAD_MIDDLE => rl.GetColor(0x275ac8FF),
                    .HEAD_LAST => rl.GetColor(0x0b07bcFF),
                    else => rl.GetColor(0x00FF00FF)
                };
            } else if (zIndex == 2) {
                cellColor = switch (item) {
                    // WTF with this bug?
                    @enumToInt(LineFeature.HEADING) => rl.GetColor(0x0000FFFF),
                    @enumToInt(LineFeature.SNIP_BEGIN) => rl.GetColor(0xFF00FFFF),
                    @enumToInt(LineFeature.SNIP_END) => rl.GetColor(0x8000FFFF),
                    @enumToInt(LineFeature.SNIP_TEXT) => rl.GetColor(0xFFFF00FF),
                    @enumToInt(LineFeature.TEXT) => rl.GetColor(0xC6C6C630),
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

                if (zIndex == 0 and item != 0) {
                    tooltipText = @tagName(@intToEnum(CharFeature, item));
                } else if (item == 0 and zIndex == 0) {
                    tooltipText = "SPACE";
                }

                if (zIndex == 1)
                    tooltipText = @tagName(@intToEnum(TokenFeature, item));

                if (zIndex == 2)
                    tooltipText = @tagName(@intToEnum(LineFeature, item));
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

        rl.EndDrawing();
    }

    rl.CloseWindow();
}
