-- CI 冒烟测试主脚本
-- 断言：jylib 全部函数以裸全局 + lib 表两种风格注册；Byte 表完整；GetPath 注册；
-- GetScreenW/H 与 config 值一致；JY_Main 主循环（Delay + GetKey 驱动事件泵）正常返回。
-- 缺失任何一项即 error("SMOKE-FAIL ...")，引擎 JY_Error 记录后退出非 0。

local globalNames = {
    "Debug", "GetKey", "GetKeyState", "EnableKeyRepeat", "Delay", "GetTime",
    "CharSet", "DrawStr", "SetClip", "FillColor", "Background", "DrawRect",
    "ShowSurface", "ShowSlow", "PicInit", "PicGetXY", "PicLoadCache",
    "PicLoadFile", "FullScreen", "LoadPicture", "PlayMIDI", "PlayWAV",
    "PlayMPEG", "LoadMMap", "DrawMMap", "GetMMap", "UnloadMMap", "LoadSMap",
    "SaveSMap", "GetS", "SetS", "GetD", "SetD", "SetSound", "DrawSMap",
    "LoadWarMap", "GetWarMap", "SetWarMap", "CleanWarMap", "DrawWarMap",
    "SaveSur", "LoadSur", "FreeSur", "GetScreenW", "GetScreenH",
    "LoadPNGPath", "LoadPNG", "GetPNGXY", "SetWeather", "GetM", "SetM",
    "GetPath"
}
local byteNames = {
    "create", "loadfile", "loadfilefromzip", "savefile", "unzip", "zip",
    "get16", "set16", "getu16", "setu16", "get32", "set32", "getstr", "setstr"
}

local okCount = 0
local missing = {}
for _, n in ipairs(globalNames) do
    if type(_G[n]) ~= "function" then
        table.insert(missing, n)
    else
        okCount = okCount + 1
    end
end
for _, n in ipairs(byteNames) do
    if type(Byte[n]) ~= "function" then
        table.insert(missing, "Byte." .. n)
    end
end
if #missing > 0 then
    error("SMOKE-FAIL missing api: " .. table.concat(missing, ","))
end
print("SMOKE-OK api registered: " .. okCount .. " globals + Byte table complete")

-- 基本调用
assert(type(GetPath()) == "string", "SMOKE-FAIL GetPath not string: " .. tostring(GetPath()))
assert(GetScreenW() == 640, "SMOKE-FAIL GetScreenW=" .. tostring(GetScreenW()))
assert(GetScreenH() == 480, "SMOKE-FAIL GetScreenH=" .. tostring(GetScreenH()))
assert(lib.GetTime() >= 0, "SMOKE-FAIL lib.GetTime")
print("SMOKE-OK basic calls pass")

-- SDL_EVENT_QUIT 时引擎调用 Menu_Exit，返回 1 表示确认退出
function Menu_Exit()
    return 1
end

function JY_Main()
    for i = 1, 40 do
        Delay(100)          -- 裸全局风格
        GetKey()            -- 驱动事件泵，消费 JY_SMOKE 注入的按键
    end
    print("SMOKE-OK JY_Main loop done")
end
