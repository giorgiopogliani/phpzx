const std = @import("std");
const rl = @import("raylib");

const phpzx = @import("phpzx");
const c = phpzx.c;


var module = phpzx.PhpModuleBuilder
    .new("autoport")
    .function("initWindow", rl.initWindow)
    .function("isMouseButtonUp", rl.isMouseButtonUp)
    .function("closeWindow", rl.closeWindow)
    .function("setTargetFPS", rl.setTargetFPS)
    .function("beginDrawing", rl.beginDrawing)
    .function("endDrawing", rl.endDrawing)
    .function("clearBackground", rl.clearBackground)
    .function("drawText", rl.drawText)
    .function("windowShouldClose", rl.windowShouldClose)
    .function("drawCircleV", rl.drawCircleV)
    .build();

export fn get_module() *c.zend_module_entry {
    return &module;
}
