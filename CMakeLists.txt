cmake_minimum_required(VERSION 3.16)
project(jysdl LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ---------- Lua 5.2.4 静态库 ----------
# MOD 字节码为 Lua 5.2 (0x52) 格式，必须用 5.2 加载
file(GLOB LUA_CORE
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lapi.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lcode.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lctype.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ldebug.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ldo.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ldump.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lfunc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lgc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/llex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lmem.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lobject.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lopcodes.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lparser.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lstate.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lstring.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ltable.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ltm.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lundump.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lvm.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lzio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lauxlib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lbaselib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lbitlib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lcorolib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ldblib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/liolib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lmathlib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/loslib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lstrlib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/ltablib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/lutf8lib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/loadlib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src/linit.c)
# 注意：不含 lua.c / luac.c / onelua.c（它们定义 main，属独立解释器）
add_library(lua52 STATIC ${LUA_CORE})
target_include_directories(lua52 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src)
if(UNIX)
    target_compile_definitions(lua52 PRIVATE LUA_USE_LINUX)
endif()

# ---------- 引擎可执行文件 ----------
set(SOURCES
    src/Audio.cpp
    src/charset.cpp
    src/jymain.cpp
    src/luafun.cpp
    src/mainmap.cpp
    src/ParticleExample.cpp
    src/ParticleSystem.cpp
    src/piccache.cpp
    src/PotConv.cpp
    src/sdlfun.cpp
    src/SimpleCC.cpp
    src/ZipFile.cpp)

add_executable(jysdl ${SOURCES})
target_include_directories(jysdl PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
# TSFMODE: 使用 TinySoundFont 合成 MIDI（避免商业 BASS 库）
target_compile_definitions(jysdl PRIVATE TSFMODE $<$<CONFIG:Release>:NDEBUG>)

find_package(SDL3 REQUIRED CONFIG COMPONENTS SDL3)
find_package(SDL3_image REQUIRED CONFIG)
find_package(SDL3_ttf REQUIRED CONFIG)
find_package(SDL3_mixer REQUIRED CONFIG)

target_link_libraries(jysdl PRIVATE
    SDL3::SDL3
    SDL3_image::SDL3_image
    SDL3_ttf::SDL3_ttf
    SDL3_mixer::SDL3_mixer
    lua52
    zip)
