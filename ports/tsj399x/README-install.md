# 天书劫原味强化版 3.99X — 开源掌机安装说明

## 这是什么

基于开源引擎 jysdl-bh（金庸群侠传 Lua 复刻版引擎的血统延续）编译的 **aarch64 Linux** 版本，
用于 ANBERNIC RG40XX V（Knulli/GarlicOS）、TrimUI Brick（CrossMix/Knulli GLIDE）等 64 位 ARM 掌机。

## 安装步骤

1. **拷入游戏数据**：把电脑版《天书劫原味强化版3.99X 最终测试版 V15.0》目录里的以下内容，
   拷进本包的 `game/` 文件夹：
   - `config.lua`（编译过的主配置）
   - `script/`（jymain.lua / jyconst.lua / event.lrk）
   - `data/`（全部 .grp/.idx、head/、pic/、sound/、help/、list/ 等）
   - `font/`（font.ttc）
   - `pic/`（虚拟按键贴图，保留）
   - ⚠️ **不要拷贝来源里的 `set.ini`**——包内已预置掌机专用版（640x480 全屏 Zoom=100）。
     如果不小心拷了，删掉它恢复包内版本。
   - 不需要的：`Legend.exe`、所有 `.dll`、`配置/`、`.bat`、`debug.txt`、`.docx/.zip`、`金庸群侠传.apk`

2. **放入掌机**：整个 `tsj399x` 文件夹拷到掌机的 ports 目录：
   - Knulli / Batocera 系：`/userdata/roms/ports/`（刷出后可见）
   - ArkOS：`/roms/ports/`
   - muOS：`/mnt/mmcRom/MUOS/roms/ports/`（或对应主 SD 卡路径）

3. **刷新与启动**：重启或刷新游戏列表 → Ports（端口）分类 → 「天书劫原味强化版3.99X」→ 启动。

## 键位（引擎内建映射）

| 掌机键 | 功能 |
|---|---|
| 十字键/D-pad | 上下左右移动、菜单选择 |
| 南键 (B/A 下键) | 确认 / Enter |
| 东键 (A/B 右键) | 取消 / Esc |
| 西键 | H 帮助 |
| 北键 | F1 |
| L 肩键 | S 系统菜单 |
| R 肩键 | L |
| Start | 弹出退出确认 |
| Select | C |

确认/取消手感不合适：改 `game/set.ini` 里 `CONFIG.SwitchABXY = 1` 交换。

## 画面

包内 `game/set.ini` 已按 4:3 640x480 掌机屏调好（全屏、Zoom=100）。
不要改成 `Zoom=0`（此引擎 0 是除零，会花屏）。

## 出问题了？

- 日志在包内：`game/debug.log`、`game/error.log`（还有 `log.txt` 是启动器输出）。
- 报 `attempt to call nil` → 引擎 API 缺口，把 log 反馈给移植者。
- 无声 → 检查 `game/data/sound/mid.sf2` 是否拷入。
- 存档位置：`game/data/save/`（与电脑版存档同格式可互拷）。

## 版权说明

引擎代码"版权所无"（jysdl-bh，游泳的鱼/蓝烟清/scarsty 血统）。
《天书劫》MOD 与《金庸群侠传》原版数据版权归其作者，本包不包含任何游戏数据。
