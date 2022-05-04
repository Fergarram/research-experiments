const std = @import("std");
const ocl = @import("ocl.zig");
const rl = @import("raylib");

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
    // outputL4: Block = undefined,

    neighbors: [8]Point = undefined,
    // 0 1 2
    // 7   3
    // 6 5 4
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

            x += 1;
        }
    }
}

pub fn main() !void {
    initializeCellMatrix(&cellMatrix, markdownString[0..markdownString.len]);

    var layer1CellBuffer = [_]u8{0} ** (128*128*5);
    var l1Count: usize = 0;

    for (cellMatrix) |col, x| {
        for (col) |_, y| {
            const cellPtr = &cellMatrix[y][x];
            if (cellPtr.* != null) {
                layer1CellBuffer[l1Count] = @enumToInt(cellPtr.*.?.outputL1);
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

    var inputImage = try ocl.createImage(
        ctx,
        .READ_WRITE,
        imageFormat,
        128,
        128,
        5
    );
    defer ocl.releaseMemObj(inputImage);

    var outputImage = try ocl.createImage(
        ctx,
        .WRITE_ONLY,
        imageFormat,
        128,
        128,
        5
    );
    defer ocl.releaseMemObj(outputImage);

    // Because this call is "blocking" it means that it will make sure that this "command"
    // will runs ASAP and will wait until it's written.
    // Altarnatively I could use events to make this not blocking.
    try ocl.enqueueWriteImageWithData(
        commandQueue,
        inputImage,
        true,
        [3]usize{0,0,0},
        [3]usize{128,128,5},
        128 * @sizeOf(u8),
        0,
        u8,
        &layer1CellBuffer
    );

    try ocl.setKernelArg(kernel, 0, &inputImage);
    try ocl.setKernelArg(kernel, 1, &outputImage);

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
        outputImage,
        true,
        [3]usize{0,0,0},
        [3]usize{128,128,5},
        128 * @sizeOf(u8),
        0,
        u8,
        &layer1CellBuffer
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

    var mouseX: c_int = 0;
    var mouseY: c_int = 0;

    while (!rl.WindowShouldClose()) {

        mouseX = @divFloor(rl.GetMouseX(), GRID_SIZE);
        mouseY = @divFloor(rl.GetMouseY(), GRID_SIZE);

        if (mouseX <= 0) mouseX = 0;
        if (mouseY <= 0) mouseY = 0;
        if (mouseX >= 127) mouseX = 127;
        if (mouseY >= 127) mouseY = 127;

        rl.BeginDrawing();

        rl.ClearBackground(rl.GetColor(0x282828FF));

        rl.DrawRectangle(UIXStart, 0, UIWidth, screenHeight, rl.LIGHTGRAY);
        rl.DrawText(rl.TextFormat("X: %03i", mouseX), (UIXStart) + 8, 8, 10, rl.BLACK);
        rl.DrawText(rl.TextFormat("Y: %03i", mouseY), (UIXStart) + 8, 24, 10, rl.BLACK);

        var tooltipText: ?[*:0]const u8 = null;

        for (layer1CellBuffer) |item| {
            const cellColor = switch (@intToEnum(CharFeature, item)) {
                .@"abc", .@"123", .@"sym" => rl.GetColor(0xC6C6C6FF),
                // .@".", => rl.GetColor(),
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
                else => rl.GetColor(0xFFFFFFFF)
            };

            if (item > 0) {
                rl.DrawCircle(
                    (GRID_SIZE/2) + (colCount * GRID_SIZE),
                    (GRID_SIZE/2) + (rowCount * GRID_SIZE),
                    GRID_SIZE/3,
                    cellColor
                );
                if (mouseX == colCount and mouseY == rowCount) {
                    tooltipText = @tagName(@intToEnum(CharFeature, item));
                }
            }

            colCount += 1;

            if (colCount == 128) {
                colCount = 0;
                rowCount += 1;
            }

            if (rowCount == 128) {
                break;
            }
        }

        colCount = 0;
        rowCount = 0;

        if (tooltipText != null) {
            rl.DrawRectangle(
                rl.GetMouseX() + 24,
                rl.GetMouseY(),
                24,
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
