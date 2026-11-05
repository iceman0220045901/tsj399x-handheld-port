# 天书劫 3.99X 开源掌机移植 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把天书劫 3.99X（Lua 复刻版引擎 MOD）跑在 RG40XX V 与 TrimUI Brick 上：patch 后的 jysdl-bh 引擎产出 aarch64 Linux 可执行文件 + PortMaster 风格移植包，GitHub Actions 云端构建。

**Architecture:** 公开 GitHub 仓库承载引擎补丁与 CI；`ubuntu:22.04` arm64 容器内源码编译 SDL3 全家桶 + Lua 5.2.4 + 引擎（CMake 可执行目标）；CI 无头冒烟（合成 Lua 测试脚本）验证 API 注册面；产物 zip = 移植包（引擎 + 捆绑 SDL3 so + 包模板），用户拷入自备游戏数据后实机验证。

**Tech Stack:** C++20/CMake、SDL3(+image/ttf/mixer)、Lua 5.2.4、libzip、GitHub Actions arm64、gh CLI 2.103.3（`tools\bin\gh.exe`）、MinGit（Task 0 下载）

**Spec:** `tsj-port/docs/specs/2026-11-05-tsj-handheld-port-design.md`

## Global Constraints

- 本机（Windows）无编译器：**一切编译验证在 CI 完成**，本地回路 = push → `gh run watch` → `gh run view --log-failed`
- 目标基线 glibc 2.35（CI 容器 `ubuntu:22.04`，runner `ubuntu-24.04-arm64`）
- Lua 版本 5.2.4（MOD 字节码魔数 `1B 4C 75 61 52`）；Lua 源码 vendor 进仓库（github.com/lua/lua tag `v5.2.4`）
- 音频编译定义 `TSFMODE`（不链接 BASS）；iconv 用 glibc 内置；libzip 用 apt
- 引擎函数**双风格注册**：`lib.*` 表 + 裸全局；`GetPath`（configLib）必须注册
- 非 Windows 且非 Android 时 `JY_CurrentPath = "./"`
- 包内 `set.ini` 模板：`Width=640 Height=480 FullScreen=1 Zoom=100`（Zoom=0 在此引擎是除零）
- 手柄映射沿用引擎 `JY_GetKey` 内建实现，不重写
- **游戏数据不入仓库**（版权）；仓库 root = `tsj-port/engine/`
- 仓库：GitHub 账号 `iceman0220045901`，公开仓库名 `tsj399x-handheld-port`
- 本地工具：gh=`tools\bin\gh.exe`；git=Task 0 下载的 MinGit（用 `GIT_CONFIG_GLOBAL` 指向 `tools/gitconfig`，不污染系统）

## Review Focus

1. **CI 编译循环是主回路**：scarsty 代码为 Windows/Android 编写，Linux 路径未验证——每轮 CI 失败读 `gh run view --log-failed` 定位，预期典型问题：C++20 vs 23 特性、MSVC 习惯写法（`localtime_s` 已有 guard）、SDL3 API 细节。测试归属：Task 4 首次 CI 绿。
2. **同名函数语义差异**（旧 Legend.exe vs scarsty 重构，如场景放大、8 层战斗）：CI 冒烟只验 API 注册面不验行为，行为差异靠 M2 实机全流程清单兜底。测试归属：Task 7 清单。
3. **手持固件 glibc**：包内二进制按 2.35 基线；CrossMix/Knulli 预期可用，旧固件报 `GLIBC_2.3x not found` 时回退方案=改 20.04 基线重建。测试归属：Task 7 首次启动。
4. **SD 卡文件系统**（FAT32/exFAT）上的存档写入与 GBK 文件名：存档写 `game/data/save/`，若失败看 error.log。测试归属：Task 7 存读档项。
5. **MIDI 无声或爆音**（tsf 懒加载 + mid.sf2 路径相对 `data/`）：进战斗听音乐。测试归属：Task 7 音乐项。

---

### Task 0: 本地 git 工具链

**Files:**
- Create: `tools/gitconfig`
- Create: `tools/mingit/`（下载解压）

**Interfaces:**
- Produces: 可用的 git 命令（`tools\mingit\cmd\git.exe` 或解压后实际路径，记录进本任务完成备注），全局身份经 `GIT_CONFIG_GLOBAL=C:\...\tools\gitconfig` 提供

- [ ] **Step 1: 解析 MinGit 最新版**（同 gh 的 atom feed 方法：`https://github.com/git-for-windows/git/releases.atom` 正则 `Repository/[0-9]+/v([0-9.]+)`）

- [ ] **Step 2: 下载并解压** `https://github.com/git-for-windows/git/releases/download/v{V}.windows.1/MinGit-{V}-64-bit.zip` 到 `tools\mingit\`（若资产名不符，从 atom 条目或 release 页核对实际资产名）

- [ ] **Step 3: 写 `tools/gitconfig`**：

```ini
[user]
	name = iceman0220045901
	email = iceman0220045901@users.noreply.github.com
[init]
	defaultBranch = main
```

- [ ] **Step 4: 验证**：`set GIT_CONFIG_GLOBAL=...\tools\gitconfig && tools\mingit\cmd\git.exe --version` 输出版本号；`tools\bin\gh.exe auth status` 显示 `Logged in as iceman0220045901`

### Task 1: 仓库骨架（引擎源码 + Lua vendor + 文档）

**Files:**
- Create: `engine/`（= research\jysdl-bh-master 全量拷贝，含 smallpot/，不含 .git）
- Create: `engine/lua-5.2.4/src/`（vendor）
- Create: `engine/docs/` ← 拷贝 `tsj-port/docs/specs/2026-11-05-tsj-handheld-port-design.md` 与本计划
- Create: `engine/.gitignore`（build*/、*.zip）

**Interfaces:**
- Produces: 本地 git 仓库 `engine/`，后续所有任务的提交与 push 均在此仓库

- [ ] **Step 1: 拷贝引擎源码**：`xcopy /E /I research\jysdl-bh-master engine`（保留 jysdllua.sln 等上游文件不动；后续补丁用 Edit 精准修改，不做大规模整理）

- [ ] **Step 2: vendor Lua 5.2.4**：下载 `https://github.com/lua/lua/archive/refs/tags/v5.2.4.zip` 解压，将其中 `src/*.c *.h` 放入 `engine/lua-5.2.4/src/`（保留 MIT 版权头，不复制其 Makefile/test 目录）

- [ ] **Step 3: git init + .gitignore + 首次提交**：在 `engine/` 执行 `git init`；提交信息 `chore: import jysdl-bh source and vendor lua 5.2.4`

- [ ] **Step 4: 验证**：`git log --oneline` 1 条；`dir lua-5.2.4\src\lua.c` 存在；`dir smallpot\include` 存在

### Task 2: CMakeLists.txt 重写（Linux 可执行目标）

**Files:**
- Modify: `engine/src/CMakeLists.txt`（整文件替换）
- Modify: `engine/src/PotDllStub.h:4`（守卫 `#ifdef __ANDROID__` → `#if defined(__ANDROID__) || defined(__linux__)`）

**Interfaces:**
- Consumes: `lua-5.2.4/src/*.c`（Task 1）
- Produces: 目标 `jysdl`（可执行），静态库目标 `lua52`；CI 构建命令 `cmake -S src -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release`

- [ ] **Step 1: 重写 `src/CMakeLists.txt`**，内容钉死为：

```cmake
cmake_minimum_required(VERSION 3.16)
project(jysdl LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Lua 5.2.4 静态库（MOD 字节码为 0x52 格式，必须 5.2 加载）
file(GLOB LUA_CORE RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src
    lua-5.2.4/src/lapi.c lua-5.2.4/src/lcode.c lua-5.2.4/src/lctype.c
    lua-5.2.4/src/ldebug.c lua-5.2.4/src/ldo.c lua-5.2.4/src/ldump.c
    lua-5.2.4/src/lfunc.c lua-5.2.4/src/lgc.c lua-5.2.4/src/llex.c
    lua-5.2.4/src/lmem.c lua-5.2.4/src/lobject.c lua-5.2.4/src/lopcodes.c
    lua-5.2.4/src/lparser.c lua-5.2.4/src/lstate.c lua-5.2.4/src/lstring.c
    lua-5.2.4/src/ltable.c lua-5.2.4/src/ltm.c lua-5.2.4/src/lundump.c
    lua-5.2.4/src/lvm.c lua-5.2.4/src/lzio.c
    lua-5.2.4/src/lauxlib.c lua-5.2.4/src/lbaselib.c lua-5.2.4/src/lbitlib.c
    lua-5.2.4/src/lcorolib.c lua-5.2.4/src/ldblib.c lua-5.2.4/src/liolib.c
    lua-5.2.4/src/lmathlib.c lua-5.2.4/src/loslib.c lua-5.2.4/src/lstrlib.c
    lua-5.2.4/src/ltablib.c lua-5.2.4/src/lutf8lib.c lua-5.2.4/src/loadlib.c
    lua-5.2.4/src/linit.c)
add_library(lua52 STATIC ${LUA_CORE})
target_include_directories(lua52 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/lua-5.2.4/src)
target_compile_definitions(lua52 PRIVATE LUA_USE_LINUX)

set(SOURCES src/Audio.cpp src/charset.cpp src/jymain.cpp src/luafun.cpp
    src/mainmap.cpp src/ParticleExample.cpp src/ParticleSystem.cpp
    src/piccache.cpp src/PotConv.cpp src/sdlfun.cpp src/SimpleCC.cpp
    src/ZipFile.cpp)
add_executable(jysdl ${SOURCES})
target_compile_definitions(jysdl PRIVATE TSFMODE)
find_package(SDL3 REQUIRED CONFIG COMPONENTS SDL3)
find_package(SDL3_image REQUIRED CONFIG)
find_package(SDL3_ttf REQUIRED CONFIG)
find_package(SDL3_mixer REQUIRED CONFIG)
target_link_libraries(jysdl PRIVATE SDL3::SDL3 SDL3_image::SDL3_image
    SDL3_ttf::SDL3_ttf SDL3_mixer::SDL3_mixer lua52 zip)
```

（若包名/目标名与实际 SDL3 CMake config 不符，以 `find_package` 报错提示为准修正 target 名；`zip` 为系统 libzip。）

- [ ] **Step 2: PotDllStub.h 守卫放宽**（Linux 下视频桩化，避免 smallpot 参与 Linux 编译）

- [ ] **Step 3: 提交** `build: linux executable cmake target with vendored lua 5.2.4`

- [ ] **Step 4: 验证**：文件内容就位（编译验证在 Task 4 CI）

### Task 3: 引擎兼容补丁（双风格注册 + GetPath + 路径）

**Files:**
- Modify: `engine/src/jymain.cpp:283-298`（main() 注册区）
- Modify: `engine/src/jymain.cpp:60-64`（JY_CurrentPath）

**Interfaces:**
- Produces: 运行期 Lua 全局 = 全部 lib 函数名 + `Byte` 表 + `GetPath`（行为与旧 ldcr 引擎注册方式对齐）

- [ ] **Step 1: JY_CurrentPath 平台分支**改为：

```c
#ifdef _WIN32
const char* JY_CurrentPath = "./";
#elif defined(__ANDROID__)
const char* JY_CurrentPath = "/sdcard/JYLDCR/";
#else
const char* JY_CurrentPath = "./";
#endif
```

- [ ] **Step 2: main() 在 `lua_setglobal(pL_main, "Byte");` 之后追加**（双风格注册：把 lib 表内全部函数提升为裸全局，并补 configLib）：

```c
    // 兼容旧 ldcr 引擎：引擎函数同时以裸全局暴露
    lua_getglobal(pL_main, "lib");
    for (const luaL_Reg* l = jylib; l->name; l++) {
        lua_getfield(pL_main, -1, l->name);
        lua_setglobal(pL_main, l->name);
    }
    lua_pop(pL_main, 1);
    // GetPath（configLib）注册进 lib 与全局
    lua_getglobal(pL_main, "lib");
    luaL_setfuncs(pL_main, configLib, 0);
    lua_pop(pL_main, 1);
    lua_newtable(pL_main);
    luaL_setfuncs(pL_main, configLib, 0);
    lua_setglobal(pL_main, "GetPath");
```

（`configLib` 当前是 static，若作用域不可见则去掉 static；`GetPath` 注册为单函数全局时注意旧引擎语义为返回路径字符串，实现后用 Task 5 的 harness 断言其非 nil 且可调用。）

- [ ] **Step 3: 提交** `fix: dual-style lua api registration, register GetPath, portable current path`

### Task 4: CI 构建阶段（SDL3 栈 + 引擎，转绿）

**Files:**
- Create: `engine/.github/workflows/build.yml`

**Interfaces:**
- Consumes: Task 2 的 CMake 目标、Task 3 补丁
- Produces: CI job `build`（绿灯）；artifact `jysdl-aarch64`（可执行文件）；后续 Task 5 在此 workflow 追加 smoke job

- [ ] **Step 1: 写 `build.yml`**，钉死的决策：runner `ubuntu-24.04-arm64`；job 级 `container: ubuntu:22.04`；apt 安装 `build-essential cmake ninja-build pkg-config libzip-dev git`；SDL3 栈从官方 release 源码编译到 `/usr/local`（SDL3 与 SDL3_image/SDL3_ttf/SDL3_mixer 均取执行时最新稳定 `release-3.x.y` tag，tag 名写入 workflow 注释）；engine 构建 `cmake --preset` 不用，直接 `-S src -B build -G Ninja -DCMAKE_BUILD_TYPE=Release`；`workflow_dispatch` + `push`（branches main）触发；artifact 名 `jysdl-aarch64`，内容 `build/src/jysdl`（按实际输出路径调整）。CMake find_package 需 `CMAKE_PREFIX_PATH=/usr/local`。

- [ ] **Step 2: push 并观察**：`git push` 后 `tools\bin\gh.exe run watch`（取最新 run id via `gh run list`）

- [ ] **Step 3: 修编译错误直到绿**（迭代回路）：每次失败 `gh run view <id> --log-failed` 定位 → 最小修复 → commit+push。预期修点：C++ 标准、`_()`/va、iconv 头、SDL3 include 名（`#include "SDL3/SDL.h"` 需与安装布局一致）、charset/ParticleSystem 的平台细节

- [ ] **Step 4: 验证**：CI job `build` 绿 + artifact `jysdl-aarch64` 可下载（`gh run download`，文件为 ARM aarch64 ELF——本地无 ARM 环境无法执行，属预期）

### Task 5: 冒烟钩子 + CI 冒烟阶段

**Files:**
- Modify: `engine/src/jymain.cpp`（main() 读环境变量、设退出期限）
- Modify: `engine/src/sdlfun.cpp`（按键事件注入点，位置以 JY_GetKey/事件泵实际结构为准）
- Create: `engine/ports/tsj399x/game-test/`（合成测试数据：`config.lua`（明文 Lua，字段与正式 set.ini 同面）+ `testmain.lua`（调用全部 lib 函数于 pcall 中 + 定义 `JY_Main` 循环 N 帧后返回）+ 空目录 `data/ pic/ script/ font/`）
- Modify: `engine/.github/workflows/build.yml`（追加 job `smoke`）

**Interfaces:**
- Consumes: Task 4 的 workflow 结构
- Produces: 环境变量协议 `JY_SMOKE=1`、`JY_SMOKE_SECONDS=<秒>`：启用 dummy 兼容的自动按键（方向/Enter/Esc 轮换）+ 超时 `SDL_EVENT_QUIT`；CI smoke 绿 = 引擎 API 注册面完整的证据

- [ ] **Step 1: 实现冒烟钩子**（最小实现：main() 读 env；SDL_AddTimer 回调向队列 push 按键事件，期限到 push QUIT；仅在 env 置位时生效）

- [ ] **Step 2: 写合成 harness**（`testmain.lua` 要点：`local names={"GetKey","Delay","DrawStr",...}` 全量枚举 jylib+Byte+GetPath，`for _,n in ipairs(names) do pcall(function() assert(_G[n] or lib[n] or Byte[n], n) end) end`；`JY_Main` 内 `Delay(10)` 循环 50 次返回；config.lua 提供 engine 所需字段同正式模板值）

- [ ] **Step 3: workflow 追加 smoke job**（依赖 build job；checkout 后用 game-test 作为工作目录运行 `JY_SMOKE=1 JY_SMOKE_SECONDS=20 SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ./build/src/jysdl`；成功判据：进程退出码 0 且 debug.log 无 `attempt to call nil`、含 `JY_Main start`）

- [ ] **Step 4: push 观察，迭代到 smoke 绿**

- [ ] **Step 5: 提交** `feat: headless smoke hook + CI smoke job with synthetic lua harness`

### Task 6: PortMaster 包模板 + 打包 artifact

**Files:**
- Create: `engine/ports/tsj399x/tsj399x.sh`
- Create: `engine/ports/tsj399x/port.json`
- Create: `engine/ports/tsj399x/game/set.ini`（正式模板，值钉死：`Width=640 Height=480 FullScreen=1 Zoom=100 EnableSound=1 MP3=1 Frame=20 LargeMemory=1 Operation=0 KeyScale=2400 PlayName="徐小侠" ZCWG="天地无用" ExpLevel=1 TP=0 SaveTime=60 Remind=0`，其余 D1X..BY=-1、ANWZ=1 与游戏原 set.ini 相同）
- Create: `engine/ports/tsj399x/README-install.md`
- Modify: `engine/.github/workflows/build.yml`（追加 job `package`）

**Interfaces:**
- Consumes: Task 4/5 的 build 产物与 SDL3 编译目录
- Produces: artifact `tsj399x-port.zip`，布局：

```
tsj399x/
  tsj399x.sh
  port.json
  README-install.md
  game/set.ini        ← 预置，用户数据不得覆盖
  jysdl
  lib/                ← libSDL3.so libSDL3_image.so libSDL3_ttf.so libSDL3_mixer.so（含依赖的 so）
```

- [ ] **Step 1: 写启动脚本** `tsj399x.sh`：

```bash
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"
export HOME="$DIR"   # 存档等写路径收敛在包内
cd "$DIR/game" || exit 1
exec "$DIR/jysdl"
```

- [ ] **Step 2: 写 port.json**（字段：name `tsj399x`、title `天书劫原味强化版3.99X`、author、description；格式对照执行时从 PortMaster 仓库样例核对一次并记录）

- [ ] **Step 3: 写 README-install.md**（中文：①把游戏本体 `config.lua script/ data/ font/ pic/` 拷入 `game/`（set.ini 已预置不要覆盖，若拷贝来源含 set.ini 则删除之）②整个 tsj399x 文件夹放到固件 ports 目录 ③PortMaster 刷新/直接在系统菜单运行 ④Knulli 与 CrossMix 的入口差异）

- [ ] **Step 4: workflow 追加 package job**：组装上述布局（SDL3 so 从 /usr/local 安装树收集 + `ldd` 闭包检查），`zip -r tsj399x-port.zip tsj399x/` 上传 artifact

- [ ] **Step 5: push 到全绿，下载 artifact 解压核对布局**（`gh run download <id> -n tsj399x-port.zip`）

- [ ] **Step 6: 提交** `feat: portmaster package template and ci packaging`

### Task 7: 实机验证循环（用户在环，M2）

**Files:**
- Modify（按需）: 引擎补丁或包模板（缺口修复迭代）

**Interfaces:**
- Consumes: Task 6 的 artifact
- Produces: 两台实机全清单通过；问题即服务（回归=CI 全绿）

- [ ] **Step 1: 用户准备数据**：从桌面游戏目录把 `config.lua script/ data/ font/ pic/` 拷入包内 `game/`（删除来源里的 set.ini，保留包内预置版）

- [ ] **Step 2: RG40XX V（Knulli）部署与清单验证**：包拷到 `/roms/ports/` → 刷新 → 启动。清单：①启动出标题 ②新开局 ③场景走动 ④进一场战斗打完 ⑤音乐音效可听 ⑥存档读档 ⑦手柄全键（十字/确认/取消/帮助/L 系统菜单/Start 退出确认）⑧退出回菜单。问题取 `game/debug.log`、`game/error.log` 反馈修复

- [ ] **Step 3: TrimUI Brick（CrossMix/Knulli GLIDE）重复 Step 2**

- [ ] **Step 4: 修复迭代**：每轮 = 改引擎/模板 → push → CI 全绿（build+smoke+package）→ 下载新 zip → 用户复测失败项

- [ ] **Step 5: 收尾**：README 补实机已知事项；最终 commit；仓库 tag `v1.0`；向用户交付仓库链接与使用说明

## Self-Review

- 规格覆盖：设计文档 10 条实现决策 → 决策1=Task2/3、2=Task3、3=Task2(lua)、4=Task2/4/6、5=沿用引擎（Task6 README 说明）、6=Task6 set.ini、7=Task6 布局、8=Task4 容器基线、9=Task5 冒烟、10=Task7 清单 ✔
- 步骤单义：各任务接口块给出精确文件/命令/判据；CI 迭代回路以"log-failed→最小修复"单一动作描述 ✔
- 类型一致：`jysdl` 目标名、artifact 名（jysdl-aarch64 / tsj399x-port.zip）、目录 `ports/tsj399x/` 全文一致 ✔
- Review Focus 5 条均有归属任务 ✔
- 比例：计划约 6 个交付物文件，无函数体转录（仅钉死 4 个小文件内容） ✔
