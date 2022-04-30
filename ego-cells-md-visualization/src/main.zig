const rl = @import("raylib");
const std = @import("std");
const print = std.debug.print;
// const ascii = std.ascii;

const fragmentScript = @embedFile("./fragment.hlsl");
// const vertexScript = @embedFile("./vertex.hlsl");

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.InitWindow(screenWidth, screenHeight, "Ego Cells: Experiment 001");
    // const shaderProgram = rl.LoadShaderFromMemory(0, fragmentScript);

    rl.SetTargetFPS(60);
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();

        rl.ClearBackground(rl.WHITE);

        // rl.BeginShaderMode(shaderProgram);
        rl.DrawCircle(80, 120, 35, rl.DARKBLUE);
        rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY);
        // rl.EndShaderMode();

        rl.EndDrawing();
    }

    rl.CloseWindow();
}
