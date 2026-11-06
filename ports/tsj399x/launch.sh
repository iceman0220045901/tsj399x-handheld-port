#!/bin/sh
# 天书劫原味强化版3.99X - TrimUI 原厂固件 PORTS 菜单入口
DIR=/mnt/SDCARD/Ports/tsj399x
export LD_LIBRARY_PATH=$DIR/libs:$LD_LIBRARY_PATH
export HOME=$DIR/game
cd $DIR/game
$DIR/jysdl 2>&1 | tee -a $DIR/log.txt
