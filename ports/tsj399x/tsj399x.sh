#!/bin/bash
# 天书劫原味强化版3.99X - 开源掌机移植（jysdl-bh 引擎 aarch64 Linux 版）
# PortMaster 约定启动脚本：适配 Knulli / Batocera / ArkOS / muOS / CrossMix 等

# PortMaster 控制接口（提供 $controlfolder/$directory/$ESUDO/$sdl_controllerconfig 等）
CF="${controlfolder:-/roms/ports/PortMaster}"
if [ -f "$CF/control.txt" ]; then
    source "$CF/control.txt"
    get_controls
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 捆绑运行库优先
export LD_LIBRARY_PATH="$DIR/libs:$LD_LIBRARY_PATH"
# 接入手柄映射（CFW 提供；引擎内建 手柄->键盘 映射读取 SDL 事件）
export SDL_GAMECONTROLLERCONFIG="${sdl_controllerconfig:-$SDL_GAMECONTROLLERCONFIG}"
# 存档/配置写路径收敛在包内（避免依赖 HOME 的未知状态）
export HOME="$DIR/game"

cd "$DIR/game" || exit 1

"$DIR/jysdl" 2>&1 | tee -a "$DIR/log.txt"

# 恢复控制台显示
printf "\033c" >> /dev/tty1 2>/dev/null || true
