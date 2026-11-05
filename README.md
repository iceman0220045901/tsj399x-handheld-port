# jysdl-ldcr — aarch64 Linux 掌机移植版

本仓库是 [scarsty/jysdl-bh](https://github.com/scarsty/jysdl-bh)（金庸群侠传 Lua 复刻版引擎血统，游泳的鱼 → 蓝烟清 → scarsty）的 **aarch64 Linux 开源掌机移植**：
让《天书劫》等 ldcr 系 MOD 跑在 RG40XX V / TrimUI Brick 等掌机上。

**移植改动**（其余代码忠实上游）：
- 根目录 `CMakeLists.txt`：Linux 可执行目标（上游为 Android 共享库），C++20，Lua 5.2.4 vendor 静态链接（MOD 字节码为 0x52 格式），音频 TSFMODE（TinySoundFont 合成 MIDI，免商业 BASS 库）
- 引擎函数**双风格注册**：`lib.*` 表 + 裸全局（旧 ldcr MOD 直呼 `GetS` 等），补注册 `GetPath`
- 非 Android 的 Linux 下工作目录为 `./`
- `JY_SMOKE` / `JY_SMOKE_SECONDS` 环境变量：CI 无头冒烟（自动按键 + 定时退出）
- `PotDllStub.h`：Linux 同 Android 桩化视频（smallpot 不参与 Linux 编译）

**构建**（aarch64 Linux，glibc ≥2.35 基线）：
```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/local
cmake --build build
```
依赖：SDL3 / SDL3_image / SDL3_ttf / SDL3_mixer（建议 release-3.x 稳定 tag 源码编译）、libzip。CI 在 GitHub Actions arm64 容器内全流程构建并产出 PortMaster 移植包（artifact `tsj399x-port`），包模板见 `ports/tsj399x/`，安装说明见 `ports/tsj399x/README-install.md`。

**本 MOD 移植计划与设计文档**：`docs/`（2026-11-05）。

---

# 上游 README（scarsty/jysdl-bh）

最初c版本由游泳的鱼编写。

蓝烟清增加功能至较为完善的版本，例如音频库改用BASS，改至SDL2等。

此版本在以上基础上添加了以下内容：

* 代码整理至c++，可以使用stl
* 改至SDL3
* 去掉了图片的链表，载入的图不再释放
* 缓存之前画过的文字，大幅提高画文字速度
* 增加了压缩文件功能
* 可以播放视频（smallpot）
* 增加按键状态的识别
* 修改了之前错误的放大场景画面的算法，改至正确的
* 战斗部分增加至8层，可以用较合理的方法画出选择范围
* 修正载入PNG图片时，连续载入同一文件的错误
* 缓存屏幕内容改为无限个，超过20个自动清理，无需再手动Free
* tmd忘了
* 清理部分代码，例如在头文件中定义变量，或者static的滥用等
* 转码和简繁转换改用iconv和opencc

目前可以认为是较完美的lua版底层，建议基于lua版制作的爱好者参考使用。

工程中附带的其他库是历史遗留问题，全部不建议直接使用，应改用vcpkg或者apt来管理依赖。
