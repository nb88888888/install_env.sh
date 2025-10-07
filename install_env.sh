#!/bin/bash
# ============================================================
# 一键部署脚本 install_env.sh
# 适用系统：Ubuntu 20.x+
# 作者：ChatGPT（GPT-5）
# 日期：2025-10
# ============================================================
set -e
LOG_FILE="/var/log/install_env.log"
IP_ADDR="152.53.240.88"
MYSQL_PORT=33061
REDIS_PORT=63791
QUEUE_PORT=63801
MONGO_PORT=32787

exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "=========================================================="
echo "🚀 开始安装环境 (日志记录: $LOG_FILE)"
echo "服务器 IP: $IP_ADDR"
echo "=========================================================="

update_system() {
  echo "[1/8] 更新系统与依赖..."
  apt-get update -y
  apt-get install -y libpcre3-dev libssl-dev perl make build-essential curl wget git autoconf docker.io || true
}

install_openresty() {
  echo "[2/8] 安装 OpenResty..."
  if [ ! -d "/usr/local/openresty" ]; then
    cd /usr/local/src
    wget -q https://openresty.org/download/openresty-1.19.3.1.tar.gz
    tar -xzf openresty-1.19.3.1.tar.gz
    cd openresty-1.19.3.1
    ./configure
    make -j$(nproc)
    make install
  else
    echo "✅ OpenResty 已存在，跳过安装。"
  fi

  grep -q "openresty" ~/.bash_profile || {
    echo 'PATH=/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:$PATH' >> ~/.bash_profile
    echo 'export LC_ALL=en_US.UTF-8' >> ~/.bash_profile
    echo 'export PATH' >> ~/.bash_profile
  }
  source ~/.bash_profile
}

install_go() {
  echo "[3/8] 安装 Go 1.18..."
  if ! command -v go >/dev/null 2>&1; then
    cd /usr/local/src
    wget -q https://studygolang.com/dl/golang/go1.18.10.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.18.10.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bash_profile
    source ~/.bash_profile
  else
    echo "✅ Go 已存在，版本：$(go version)"
  fi
}

install_skynet() {
  echo "[4/8] 安装 Skynet..."
  mkdir -p /data
  if [ ! -d "/data/skynet" ]; then
    cd /data
    git clone https://gitee.com/mirrors/skynet.git
    cd skynet && make linux
  else
    echo "✅ Skynet 已存在，跳过下载。"
  fi
}

install_docker() {
  echo "[5/8] 检查 Docker 服务..."
  systemctl enable docker
  systemctl start docker
  docker ps >/dev/null 2>&1 || echo "⚠️ Docker 启动可能存在问题，请检查。"
}

install_mysql() {
  echo "[6/8] 部署 MySQL 容器..."
  mkdir -p /data/mysqldb_dir
  docker pull mysql:5.7.27
  docker rm -f mysql >/dev/null 2>&1 || true
  docker run --name mysql \
    -e MYSQL_ROOT_PASSWORD=admin123456! \
    -v /data/mysqldb_dir:/var/lib/mysql \
    -p $IP_ADDR:$MYSQL_PORT:3306 -d mysql:5.7.27
}

install_redis() {
  echo "[7/8] 部署 Redis 容器..."
  mkdir -p /data/redisdb_dir /data/queuedb_dir
  docker pull redis:5.0
  docker rm -f redis queue >/dev/null 2>&1 || true
  docker run --name redis \
    -v /data/redisdb_dir:/data \
    -p $IP_ADDR:$REDIS_PORT:6379 -d redis:5.0 --appendonly yes
  docker run --name queue \
    -v /data/queuedb_dir:/data \
    -p $IP_ADDR:$QUEUE_PORT:6379 -d redis:5.0 --appendonly yes
}

install_mongo() {
  echo "[8/8] 部署 MongoDB 容器..."
  mkdir -p /data/mongodb_dir
  docker pull mongo:4.0.10
  docker rm -f mongo >/dev/null 2>&1 || true
  docker run --name mongo \
    -v /data/mongodb_dir:/data/db \
    -p $IP_ADDR:$MONGO_PORT:27017 -d mongo:4.0.10
}

create_proj_dirs() {
  echo "📁 创建项目结构..."
  mkdir -p /data/proj/{config,apiserver,loginserver,gameserver,common,skynet,pyapi,goserver}
}

finish_summary() {
  echo "=========================================================="
  echo "✅ 环境安装完成！请执行以下操作："
  echo "1️⃣ 上传项目代码至 /data/proj/"
  echo "2️⃣ 使用 start_all.sh 启动服务"
  echo ""
  echo "📡 服务端口信息："
  echo "MySQL  : $IP_ADDR:$MYSQL_PORT (root/admin123456!)"
  echo "Redis  : $IP_ADDR:$REDIS_PORT"
  echo "Queue  : $IP_ADDR:$QUEUE_PORT"
  echo "MongoDB: $IP_ADDR:$MONGO_PORT"
  echo "=========================================================="
}

# 执行流程
update_system
install_openresty
install_go
install_skynet
install_docker
install_mysql
install_redis
install_mongo
create_proj_dirs
finish_summary
