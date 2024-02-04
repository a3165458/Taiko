#!/bin/bash

# 1. 更新系统包列表并升级所有已安装的包
sudo apt update && sudo apt upgrade -y

# 2. 安装基本组件，包括编译工具、库和其他必要的软件包
sudo apt install pkg-config curl git-all build-essential libssl-dev libclang-dev ufw -y

# 3. 检查 Docker 是否已安装并且是最新版本
docker version
# 如果 Docker 未安装，执行以下命令安装 Docker 所需的依赖
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


# 现在安装 Docker Compose
sudo apt install docker-compose -y

# 验证 Docker Engine 安装是否成功
sudo docker run hello-world
# 你应该看到 hello-world 程序的输出

# 检查 Docker Compose 版本
docker-compose -v

# 克隆 Taiko 仓库
git clone https://github.com/taikoxyz/simple-taiko-node.git

# 进入 Taiko 目录
cd simple-taiko-node

# 复制示例环境变量文件
cp .env.sample .env

read -p "输入L1 HTTP 链接: " L1_ENDPOINT_HTTP
read -p "输入L1 WSS 链接: " L1_ENDPOINT_WS
read -p "输入是否允许作为Prover角色（true/false）: " ENABLE_PROVER
read -p "输入L1 EVM 私钥: " L1_PROVER_PRIVATE_KEY

# Write to the .env file
echo "L1_ENDPOINT_HTTP=$L1_ENDPOINT_HTTP" >> ".env"
echo "L1_ENDPOINT_WS=$L1_ENDPOINT_WS" >> ".env"
echo "ENABLE_PROVER=$ENABLE_PROVER" >> ".env"
echo "L1_PROVER_PRIVATE_KEY=$L1_PROVER_PRIVATE_KEY" >> ".env"


# 运行 Taiko 节点
docker compose up -d
