#!/bin/bash
# ===========================================
# 一键启动所有服务脚本
# ===========================================

set -e

echo "[1/6] 启动 OpenResty (apiserver)..."
cd /data/proj/apiserver
nginx -p `pwd` -c conf/nginx.conf || true

echo "[2/6] 启动登录服务器..."
cd /data/proj/skynet
./skynet ../loginserver/prodconfig & echo $! > loginskynet.pid

echo "[3/6] 启动游戏服务器..."
cd /data/proj/skynet
./skynet ../gameserver/prodconfig & echo $! > gameskynet.pid

echo "[4/6] 启动 Go 管理后台..."
cd /data/proj/goserver
./mygo & echo $! > goserver.pid

echo "[5/6] 启动 Python 客服服务..."
cd /data/proj/pyapi/kefu
nohup python3 main.py > kefu.log 2>&1 & echo $! > kefu.pid

echo "[6/6] 启动微信支付服务..."
cd /data/proj/pyapi/wxpay
sh start.sh

echo "✅ 所有服务已启动。"
echo "---------------------------------------"
echo "Nginx         : 运行中 (apiserver)"
echo "LoginServer   : PID $(cat /data/proj/skynet/loginskynet.pid)"
echo "GameServer    : PID $(cat /data/proj/skynet/gameskynet.pid)"
echo "GoServer      : PID $(cat /data/proj/goserver/goserver.pid)"
echo "PyAPI-Kefu    : PID $(cat /data/proj/pyapi/kefu/kefu.pid)"
echo "Mongo/Redis/MySQL 已通过 Docker 运行。"
echo "---------------------------------------"
