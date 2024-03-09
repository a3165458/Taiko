#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Taiko.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="taiko"
    local shell_rc="$HOME/.bashrc"

    # 对于Zsh用户，使用.zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # 检查快捷键是否已经设置
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "设置快捷键 '$alias_name' 到 $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # 添加提醒用户激活快捷键的信息
        echo "快捷键 '$alias_name' 已设置。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        # 如果快捷键已经设置，提供一个提示信息
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
        echo "如果快捷键不起作用，请尝试运行 'source $shell_rc' 或重新打开终端。"
    fi
}

# 节点安装功能
function install_node() {

# 更新系统包列表
sudo apt update

# 检查 Git 是否已安装
if ! command -v git &> /dev/null
then
    # 如果 Git 未安装，则进行安装
    echo "未检测到 Git，正在安装..."
    sudo apt install git -y
else
    # 如果 Git 已安装，则不做任何操作
    echo "Git 已安装。"
fi

# 克隆 Taiko 仓库
git clone https://github.com/taikoxyz/simple-taiko-node.git

# 进入 Taiko 目录
cd simple-taiko-node

# 如果不存在.env文件，则从示例创建一个
if [ ! -f .env ]; then
  cp .env.sample .env
fi

# 提示用户输入环境变量的值
read -p "请输入BlockPI holesky HTTP链接: " l1_endpoint_http
read -p "请输入BlockPI holesky WS链接: " l1_endpoint_ws
read -p "请确认是否作为提议者（可选true或者false，建议输入true）: " enable_proposer
read -p "请输入EVM钱包私钥: " l1_proposer_private_key

# 检测并罗列未被占用的端口
function list_recommended_ports {
    local start_port=8000 # 可以根据需要调整起始搜索端口
    local needed_ports=7
    local count=0
    local ports=()

    while [ "$count" -lt "$needed_ports" ]; do
        if ! ss -tuln | grep -q ":$start_port " ; then
            ports+=($start_port)
            ((count++))
        fi
        ((start_port++))
    done

    echo "推荐的端口如下："
    for port in "${ports[@]}"; do
        echo -e "\033[0;32m$port\033[0m"
    done
}

# 使用推荐端口函数为端口配置
list_recommended_ports

# 提示用户输入端口配置，允许使用默认值
read -p "请输入L2执行引擎HTTP端口 [默认: 8547]: " port_l2_execution_engine_http
port_l2_execution_engine_http=${port_l2_execution_engine_http:-8547}

read -p "请输入L2执行引擎WS端口 [默认: 8548]: " port_l2_execution_engine_ws
port_l2_execution_engine_ws=${port_l2_execution_engine_ws:-8548}

read -p "请输入L2执行引擎Metrics端口 [默认: 6060]: " port_l2_execution_engine_metrics
port_l2_execution_engine_metrics=${port_l2_execution_engine_metrics:-6060}

read -p "请输入L2执行引擎P2P端口 [默认: 30306]: " port_l2_execution_engine_p2p
port_l2_execution_engine_p2p=${port_l2_execution_engine_p2p:-30306}

read -p "请输入证明者服务器端口 [默认: 9876]: " port_prover_server
port_prover_server=${port_prover_server:-9876}

read -p "请输入Prometheus端口 [默认: 9091]: " port_prometheus
port_prometheus=${port_prometheus:-9091}

read -p "请输入Grafana端口 [默认: 3001]: " port_grafana
port_grafana=${port_grafana:-3001}

# 将用户输入的值写入.env文件
sed -i "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=${l1_endpoint_http}|" .env
sed -i "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=${l1_endpoint_ws}|" .env
sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=${enable_proposer}|" .env
sed -i "s|L1_PROPOSER_PRIVATE_KEY=.*|L1_PROPOSER_PRIVATE_KEY=${l1_proposer_private_key}|" .env

# 更新.env文件中的端口配置
sed -i "s|PORT_L2_EXECUTION_ENGINE_HTTP=.*|PORT_L2_EXECUTION_ENGINE_HTTP=${port_l2_execution_engine_http}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_WS=.*|PORT_L2_EXECUTION_ENGINE_WS=${port_l2_execution_engine_ws}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_METRICS=.*|PORT_L2_EXECUTION_ENGINE_METRICS=${port_l2_execution_engine_metrics}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_P2P=.*|PORT_L2_EXECUTION_ENGINE_P2P=${port_l2_execution_engine_p2p}|" .env
sed -i "s|PORT_PROVER_SERVER=.*|PORT_PROVER_SERVER=${port_prover_server}|" .env
sed -i "s|PORT_PROMETHEUS=.*|PORT_PROMETHEUS=${port_prometheus}|" .env
sed -i "s|PORT_GRAFANA=.*|PORT_GRAFANA=${port_grafana}|" .env
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=http://taiko-a6-prover.zkpool.io|" .env

# 用户信息已配置完毕
echo "用户信息已配置完毕。"

# 升级所有已安装的包
sudo apt upgrade -y

# 安装基本组件
sudo apt install pkg-config curl build-essential libssl-dev libclang-dev ufw -y

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    # 如果 Docker 未安装，则进行安装
    echo "未检测到 Docker，正在安装..."
    sudo apt-get install ca-certificates curl gnupg lsb-release

    # 添加 Docker 官方 GPG 密钥
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 授权 Docker 文件
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update

    # 安装 Docker 最新版本
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
else
    echo "Docker 已安装。"
fi

# 检查 Docker Compose 是否已安装
if ! command -v docker-compose &> /dev/null
then
    echo "未检测到 Docker Compose，正在安装..."
    sudo apt install docker-compose -y
else
    echo "Docker Compose 已安装。"
fi

# 验证 Docker Engine 安装是否成功
sudo docker run hello-world
# 应该能看到 hello-world 程序的输出

# 检查 Docker Compose 版本
docker-compose -v

# 运行 Taiko 节点
docker compose up -d

# 获取公网 IP 地址
public_ip=$(curl -s ifconfig.me)

# 准备原始链接
original_url="LocalHost:${port_grafana}/d/L2ExecutionEngine/l2-execution-engine-overview?orgId=1&refresh=10s"

# 替换 LocalHost 为公网 IP 地址
updated_url=$(echo $original_url | sed "s/LocalHost/$public_ip/")

# 显示更新后的链接
echo "请通过以下链接查询设备运行情况，如果无法访问，请等待2-3分钟后重试：$updated_url"

}

# 查看节点日志
function check_service_status() {
    cd simple-taiko-node
    docker compose logs -f --tail 20
}



# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "================================================================"
    echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
    echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    echo "3. 设置快捷键的功能"
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) check_and_set_alias ;; 
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
