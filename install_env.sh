#!/bin/bash
# ===========================================
# 环境安装脚本 (Ubuntu 20.x)
# 安装 OpenResty + Skynet + Go + Docker + MySQL + Redis + Mongo
# ===========================================
set -e
export LC_ALL=en_US.UTF-8

echo "[1/8] 更新系统与安装依赖..."
apt-get update -y
apt-get install -y libpcre3-dev libssl-dev perl make build-essential curl wget git autoconf docker.io

echo "[2/8] 安装 OpenResty..."
cd /usr/local/src
wget https://openresty.org/download/openresty-1.19.3.1.tar.gz
tar -xzf openresty-1.19.3.1.tar.gz
cd openresty-1.19.3.1
./configure
make -j$(nproc)
make install

PROFILE_FILE=~/.bash_profile
{
  echo 'PATH=/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:$PATH'
  echo 'export LC_ALL=en_US.UTF-8'
  echo 'export PATH'
  echo 'export PATH=$PATH:/usr/local/go/bin'
} >> $PROFILE_FILE
source $PROFILE_FILE

echo "[3/8] 安装 Go..."
cd /usr/local/src
wget https://studygolang.com/dl/golang/go1.18.10.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.18.10.linux-amd64.tar.gz

echo "[4/8] 下载 Skynet..."
mkdir -p /data
cd /data
git clone https://gitee.com/mirrors/skynet.git
cd skynet
make linux

echo "[5/8] 启动 Docker..."
systemctl enable docker
systemctl start docker

echo "[6/8] 安装 MySQL..."
mkdir -p /data/mysqldb_dir
docker pull mysql:5.7.27
docker run --name mysql \
  -e MYSQL_ROOT_PASSWORD=admin123456! \
  -v /data/mysqldb_dir:/var/lib/mysql \
  -p 152.53.240.88:33061:3306 -d mysql:5.7.27

echo "[7/8] 安装 Redis..."
mkdir -p /data/redisdb_dir /data/queuedb_dir
docker pull redis:5.0
docker run --name redis \
  -v /data/redisdb_dir:/data \
  -p 152.53.240.88:63791:6379 -d redis:5.0 --appendonly yes
docker run --name queue \
  -v /data/queuedb_dir:/data \
  -p 152.53.240.88:63801:6379 -d redis:5.0 --appendonly yes

echo "[8/8] 安装 MongoDB..."
mkdir -p /data/mongodb_dir
docker pull mongo:4.0.10
docker run --name mongo \
  -v /data/mongodb_dir:/data/db \
  -p 152.53.240.88:32787:27017 -d mongo:4.0.10

echo "✅ 安装完成。请上传项目文件到 /data/proj 并执行 start_all.sh 启动。"
