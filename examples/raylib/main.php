<?php

$screenWidth = 800;
$screenHeight = 450;

initWindow($screenWidth, $screenHeight, 'php zig raylib example');

setTargetFPS(60);

while (!windowShouldClose()) {
    beginDrawing();

    clearBackground(0xFFFFFFFF);
    drawText('hello from php', 200, 200, 20, 0xFF222222);
    if (isMouseButtonUp(0)) {
        drawCircleV([200.0, 300.0], 50.0, 0xFF000000);
    } else {
        drawCircleV([200.0, 300.0], 50.0, 0xFF009900);
    }

    endDrawing();
}

closeWindow();
