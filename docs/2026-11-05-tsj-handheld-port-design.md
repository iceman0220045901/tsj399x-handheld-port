# 天书劫原味强化版 3.99X 开源掌机移植 — 设计文档

日期：2026-11-05
状态：待用户批准
目标用户：游戏《天书劫原味强化版 3.99X 最终测试版》的持有者（本机用户本人）
目标设备：ANBERNIC RG40XX V（Allwinner H700，aarch64，Knulli/GarlicOS）、TrimUI Brick（Allwinner A133P，aarch64，CrossMix/Knulli 系固件）

## 意图与动机

把基于《金庸群侠传》Lua 复刻版引擎（民间称 Legend 引擎）的 MOD《天书劫原味强化版 3.99X》移植到开源掌机上，装进掌机的 Ports 菜单即可游玩，不改变游戏内容本身。

## 现状（已核实的调研事实）

- **MOD 已在 ldcr 引擎血统上端到端运行过**：游戏包内自带安卓 APK（`cn.vip.ldcr` 包名，BASS+SDL2+Lua5.2，54KB libmain.so）即蓝烟清 ldcr 引擎的安卓版，MOD 随包提供"安卓版配置"就是为它准备的。scarsty/jysdl-bh 是该引擎的重构延续（同名函数 Lua_Config/Lua_Main/Config_GetPath 可在 APK so 中找到）。未验证部分：scarsty 重构引入的行为修正（场景放大算法、8 层战斗、PNG 缓存等）在 MOD 全流程下的表现 → 用前置里程碑 M1（见实现决策 10）兜底
- 游戏本体 = 封闭源码的 PC 引擎 `Legend.exe`（SDL2+BASS+内嵌 Lua 5.2）+ 游戏数据：
  - `config.lua` / `script/jymain.lua`(743KB) / `script/jyconst.lua` / `script/event.lrk` / `data/newconst.lua` 均为**标准未加密 Lua 5.2 字节码**（魔数 `1B 4C 75 61 52`，LuaR 实为 `ESC "Lua" 0x52`）
  - `data/` 为 1996 原版金庸二进制格式（.grp/.idx），`data/head|pic` 为 PNG，`data/sound/` = 293 个 WAV 音效 + 33 首 MIDI 背景乐 + `mid.sf2` 音色库（5.97MB）
  - `set.ini` 是被 `config.lua` dofile 的明文 Lua 覆盖配置（宽高、按键、音频开关等在此改）
- 引擎开源血统：游泳的鱼 jylua → 蓝烟清（BASS/SDL2）→ **scarsty/jysdl-bh**（自述 jysdl-ldcr，同一 JYLDCR 生态），源码头部声明"版权所无，可以任何方式使用"
- 兼容性已验证（三轮）：① MOD 字节码字符串扫描 vs jysdl-bh 注册 API；② 随包安卓 APK libmain.so 内嵌的旧引擎注册名单（44 个 lib 函数 + Byte 11 项 + GetPath）vs jysdl-bh——**全覆盖**；③ 差异项：旧引擎以裸全局暴露函数（`GetS(...)` 直呼），scarsty 版只注册进 `lib` 表 → 见实现决策 2 双风格注册；`GetPath` 在 scarsty 版有实现但未注册（configLib 挂空）→ 补注册
- scarsty 版音频双模式：BASSMODE（商业库）或 **TSFMODE**（SDL3_mixer + TinySoundFont 合成 MIDI，tsf.h/tml.h 已随源码附带）→ Linux 用 TSF 模式，无需 BASS
- scarsty 已编译过 arm64 Android 版（CMakeLists 指向 vcpkg arm64-android），ARM64 编译可行性已被作者本人验证；但当前 CMake 仅有 Android 共享库目标，无 Linux 可执行目标
- 两台目标机均为 aarch64 四核 A53 + 640x480 4:3 屏；掌机固件装移植包的事实标准是 PortMaster（Knulli/CrossMix/muOS 均支持）
- 本机（Windows）无编译器/WSL/Docker
- 安卓手机已有现成 APK（游戏包内附带），不在本次移植范围

## 目标

1. jysdl-bh 引擎产出 **aarch64 Linux 可执行文件**（glibc，兼容 Knulli/CrossMix 用户态）
2. 打包成 **PortMaster 风格移植包**：拷入掌机 ports 目录 + 用户自备游戏数据 → 菜单里直接启动
3. 手柄完整操控（沿用安卓版键位语义），640x480 4:3 全屏正确显示、比例不变形
4. 音乐音效完整（WAV + MIDI via SF2）
5. 存档与 PC 版互通（同引擎同格式，`data/save/*.grp` 直接拷贝读写）

## 非目标 / 反目标

- 非目标：不修改游戏内容（MOD 数值/剧情/脚本一律不动）；不做 Windows/安卓/iOS 版本（Windows 开发版已被用户否决）；不做联网、成就、金手指
- 反目标（出现即视为失败）：在目标固件上无法启动；画面比例变形或花屏；战斗/MIDI 死循环或崩溃；存档损坏；需要 root 或重刷固件才能玩

## 约束

- MOD 数据文件（天书劫）版权归其作者：**移植包不内嵌游戏数据**，包内附"数据放置说明"，用户把自己的游戏文件拷入指定目录
- 引擎源码无版权限制，可自由修改与分发
- 音频走 TSF 开源合成，规避 BASS 商业库
- 本机无工具链 → 构建在云端 CI（GitHub Actions 公开仓库的 arm64 runner）完成，产物为可直接下载的移植包 zip
- 目标固件用户态：glibc（Knulli/Batocera/CrossMix 均为 glibc Linux）；SDL3 等运行库不依赖固件自带，随包捆绑

## 方案取舍（已选定 A）

- **A. jysdl-bh 移植（选定）**：现代开源引擎，API 已核对兼容，作者已验证 ARM64；代价是需要自己补 Linux 可执行目标、捆绑 SDL3 运行库，存在少量 API 缺口需运行期迭代补齐（概率低、成本低）
- B. 寻找蓝烟清原版 Legend 引擎源码：还原度理论 100%，但源码公开性未知，检索可能死胡同；BASS 依赖商业库 → 放弃
- C. 掌机 Wine+Box64 跑 Legend.exe：零移植但体验差（500MB+ 环境、弱芯片勉强）、不标准 → 仅作最终兜底

## 已定的实现决策（用户选定 A 后，以下为实现者职责内的设计决定）

1. **引擎改造**（fork scarsty/jysdl-bh，最小补丁）：
   - 新增 `add_executable` 目标（现有源文件集合不变），去掉 vcpkg Android 硬编码路径，改用标准 CMake find/link
   - 非 Windows 下 `JY_CurrentPath` 由 `/sdcard/JYLDCR/` 改为可执行文件所在目录（或 `./`），允许环境变量 `JY_PATH` 覆盖
   - C++ 标准若工具链对 C++23 支持不全则降至 C++20（scarsty 源码预计兼容，构建期验证）
2. **双风格 API 注册**（关键兼容补丁）：scarsty 版把引擎函数注册进 `lib` 表，旧 ldcr 引擎注册为裸全局，天书劫以裸全局直呼。移植版在 `main()` 注册 lib/Byte 表后，遍历同一 luaL_Reg 表把全部函数再 `lua_setglobal` 一份，并补注册 `configLib`（`GetPath`）为全局与 `lib.GetPath`；`Byte` 表旧版缺 zip 相关三项（新引擎超集，无碍）
3. **Lua 5.2.4**：源码并入构建（单 C 库，静态链接），保证加载 0x52 字节码；engine 代码使用的 lua API（luaL_setfuncs/luaL_Reg 等）与 5.2 兼容
4. **依赖**：SDL3 + SDL3_image + SDL3_ttf + SDL3_mixer 从官方稳定 tag 在 CI 源码编译；iconv 用 glibc 内置；简繁转换按 scarsty 实现依赖 4 个词表文件（STCharacters.txt 等，静默降级），无需 opencc 库；libzip 用 apt（ZipFile.cpp 确认需要）；smallpot 视频播放为可选桩（本 MOD 未用，直接禁用相关调用）
5. **手柄输入（采用引擎内建映射，不自创）**：scarsty 的 `JY_GetKey` 已实现完整手柄映射——南键(S)=Enter 确认、东键(E)=Esc 取消、北键(N)=F1、西键(W)=H 帮助、L 肩键=S 系统菜单、R 肩键=L、Select(Back)=C、Start=经 Lua `Menu_Exit` 弹出退出确认；`CONFIG.SwitchABXY` 可交换确认/取消位置。移植不做映射重写，仅按实机手感微调（微调属实现者职责）
6. **画面**：移植包内置**干净的** `set.ini`（被 config.lua dofile 覆盖 CONFIG）：Width=640 Height=480 FullScreen=1 **Zoom=100**。注意：scarsty 引擎中 Zoom 是除数/乘数，0 会除零导致花屏（旧 Legend.exe 语义不同），故不能用游戏自带 set.ini 的 Zoom=0 原值；保留 `CONFIG.Zoom` 用户可调
7. **打包布局**（PortMaster 规范）：
   ```
    ports/tsj399x/
      tsj399x.sh          # 启动脚本：export LD_LIBRARY_PATH=.；cd game；exec ../jysdl
      jysdl               # aarch64 可执行
      libSDL3*.so         # 捆绑运行库
      control.txt / tsj399x.json  # PortMaster 元数据
      game/               # 用户自备游戏数据（config.lua、script/、data/、font/、pic/、set.ini）
   ```
8. **构建与兼容基线**：GitHub Actions 公开仓库，`ubuntu-24.04-arm64` runner 上以 **ubuntu:20.04 arm64 容器**为构建环境（glibc 2.31 基线，兼容 Knulli/Batocera 2.36+、CrossMix、muOS 等较旧用户态，避免 "GLIBC_2.3x not found"）；依赖库同容器内源码编译；一键 workflow 产出移植包 zip artifact；附带 CI 冒烟测试（SDL dummy video driver 启动 30 秒读 debug.log 无致命错误即过）
9. **兼容缺口迭代回路（用户已定：不做 Windows 开发版，直接以 CI 冒烟 + 掌机实测迭代）**：
   - **M1 里程碑 = CI 无头冒烟跑真实游戏数据**：引擎加冒烟钩子（环境变量 `JY_SMOKE=1` + `JY_SMOKE_SECONDS`：SDL dummy 视频驱动、定时自动注入方向/Enter/Esc 按键、超时自动退出）——CI 在 ubuntu:20.04 arm64 容器里用真实游戏数据跑 60 秒，检查 debug.log/error.log 是否出现 "attempt to call nil" 类缺口与关键进度标记（"JY_Main start"、"Start game cycle" 等）→ 有缺口就地修引擎，无缺口才产出掌机包
   - **M2 = 掌机实测**：用户拷入两台掌机实测，错误从游戏目录的 debug.log/error.log 读取
10. **验证清单**：新开局 → 进场景走动 → 进一场战斗打完 → 音乐音效可听 → 存档/读档 → 手柄全键位过一遍（M2 在两台实机上逐项确认）

## 留给实现者的事项

- jysdl-bh 具体编译错误的修复细节；SDL3 在 CI 容器内的具体版本/tag 选择
- 双风格注册的具体实现方式（遍历 luaL_Reg 逐个 lua_setglobal）
- 按键映射的最终手感调优（以实机体验为准；基准=实现决策 5 的引擎内建映射）
- CI 产物命名与版本号（jysdl-1.0.0-tsj399x 等）
- （可选加固）用 PowerShell/Lua 5.2 字节码解析器对全部 5 个脚本文件做 GETTABUP 全局引用精确提取，替代字符串级推断

## 已由用户确认的事项

1. 构建链：**创建 GitHub 公开仓库**（引擎补丁 + workflow，CI 产出 zip）；本机 gh CLI 待安装
2. 迭代方式：**不做 Windows 开发版**，以 CI 无头冒烟（真实数据）+ 掌机实测回路迭代
