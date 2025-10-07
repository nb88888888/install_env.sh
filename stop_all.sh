#!/bin/bash
echo "停止所有服务..."
cd /data/proj/skynet
kill -9 $(cat loginskynet.pid 2>/dev/null) 2>/dev/null || true
kill -9 $(cat gameskynet.pid 2>/dev/null) 2>/dev/null || true
cd /data/proj/goserver && kill -9 $(cat goserver.pid 2>/dev/null) 2>/dev/null || true
cd /data/proj/pyapi/kefu && kill -9 $(cat kefu.pid 2>/dev/null) 2>/dev/null || true
cd /data/proj/apiserver && nginx -p `pwd` -c conf/nginx.conf -s stop || true
echo "✅ 所有服务已停止。"
