#!/bin/bash

# 1. 更新系统包列表并升级所有已安装的包
sudo apt update && sudo apt upgrade -y

# 2. 安装基本组件，包括编译工具、库和其他必要的软件包
sudo apt install pkg-config curl git-all build-essential libssl-dev libclang-dev ufw -y

# 3. 检查 Docker 是否已安装并且是最新版本
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found, installing..."
    sudo apt-get install ca-certificates curl gnupg lsb-release

    # 添加 Docker 的官方 GPG 密钥
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 为 Docker 文件授权，以防万一，然后更新包索引
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update

    # 安装 Docker 的最新版本
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
else
    echo "Docker is already installed."
fi

# 现在检查 Docker Compose 是否已安装
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose could not be found, installing..."
    sudo apt install docker-compose -y
else
    echo "Docker Compose is already installed."
fi

# 验证 Docker Engine 安装是否成功
sudo docker run hello-world
# 你应该看到 hello-world 程序的输出

# 检查 Docker Compose 版本
docker-compose -v

# 克隆 Taiko 仓库
git clone https://github.com/taikoxyz/simple-taiko-node.git

# 进入 Taiko 目录
cd simple-taiko-node

# 如果不存在.env文件，则从示例创建一个
if [ ! -f .env ]; then
  cp .env.sample .env
fi

# 提示用户输入环境变量的值
read -p "输入BlockPI holesky HTTP链接: " l1_endpoint_http
read -p "输入BlockPI holesky WS链接: " l1_endpoint_ws
read -p "确认是否作为证明者（输入True或者False）: " enable_prover
read -p "输入0x开头的EVM钱包私钥: " l1_prover_private_key

# 将用户输入的值写入.env文件
sed -i "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=${l1_endpoint_http}|" .env
sed -i "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=${l1_endpoint_ws}|" .env
sed -i "s|ENABLE_PROVER=.*|ENABLE_PROVER=${enable_prover}|" .env
sed -i "s|L1_PROVER_PRIVATE_KEY=.*|L1_PROVER_PRIVATE_KEY=${l1_prover_private_key}|" .env

# 提示信息
echo "用户信息已经配置。"

# 运行 Taiko 节点
docker compose up -d

# 进入网页查询
public_ip=$(curl -s ifconfig.me)

# 原始链接，其中的 LocalHost 将被替换
original_url="LocalHost:3001/d/L2ExecutionEngine/l2-execution-engine-overview?orgId=1&refresh=10s"

# 替换 LocalHost 为公网 IP 地址
updated_url=$(echo $original_url | sed "s/LocalHost/$public_ip/")

