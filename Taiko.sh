#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/manage_taiko.sh"

# 安装节点功能
function install_node() {
    # 更新系统包列表
    sudo apt update

    # 检查 Git 是否已安装
    if ! command -v git &> /dev/null; then
        echo "未检测到 Git，正在安装..."
        sudo apt install git -y
    else
        echo "Git 已安装。"
    fi

    # 克隆 Taiko 仓库
    if [ ! -d "simple-taiko-node" ]; then
        git clone https://github.com/taikoxyz/simple-taiko-node.git
    else
        echo "Taiko 仓库已经存在。"
    fi

    # 进入 Taiko 目录
    pushd simple-taiko-node || exit

    # 如果不存在.env文件，则从示例创建一个
    if [ ! -f .env ]; then
        cp .env.sample .env
    fi

# 提示用户输入环境变量的值
read -p "请输入BlockPI holesky HTTP链接: " l1_endpoint_http

read -p "请输入BlockPI holesky WS链接: " l1_endpoint_ws

read -p "请确认是否作为证明者（输入true或者false）: " enable_prover

read -p "请输入0x开头的EVM钱包私钥: " l1_prover_private_key

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
sed -i "s|ENABLE_PROVER=.*|ENABLE_PROVER=${enable_prover}|" .env
sed -i "s|L1_PROVER_PRIVATE_KEY=.*|L1_PROVER_PRIVATE_KEY=${l1_prover_private_key}|" .env

# 更新.env文件中的端口配置
sed -i "s|PORT_L2_EXECUTION_ENGINE_HTTP=.*|PORT_L2_EXECUTION_ENGINE_HTTP=${port_l2_execution_engine_http}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_WS=.*|PORT_L2_EXECUTION_ENGINE_WS=${port_l2_execution_engine_ws}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_METRICS=.*|PORT_L2_EXECUTION_ENGINE_METRICS=${port_l2_execution_engine_metrics}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_P2P=.*|PORT_L2_EXECUTION_ENGINE_P2P=${port_l2_execution_engine_p2p}|" .env
sed -i "s|PORT_PROVER_SERVER=.*|PORT_PROVER_SERVER=${port_prover_server}|" .env
sed -i "s|PORT_PROMETHEUS=.*|PORT_PROMETHEUS=${port_prometheus}|" .env
sed -i "s|PORT_GRAFANA=.*|PORT_GRAFANA=${port_grafana}|" .env

    # 用户信息已配置完毕
    echo "用户信息已配置完毕。"

    # 升级所有已安装的包
    sudo apt upgrade -y

    # 安装基本组件
    sudo apt install pkg-config curl build-essential libssl-dev libclang-dev ufw -y

    install_docker

    # 运行 Taiko 节点
    docker compose down && docker compose up -d

    # 返回原始目录
    popd
}

# 安装 Docker 和 Docker Compose
function install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "安装Docker..."
        sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    else
        echo "Docker 已安装。"
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "安装Docker Compose..."
        sudo apt install docker-compose -y
    else
        echo "Docker Compose 已安装。"
    fi
}

# 查看 Docker Compose 日志
function view_logs() {
    pushd simple-taiko-node || exit
    docker compose logs -f
    popd
}

# 写入快捷键
function check_and_set_alias() {
    local alias_name="taikof"
    local shell_rc="$HOME/.bashrc"

    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    if ! grep -q "alias $alias_name=" "$shell_rc"; then
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        echo "快捷键 '$alias_name' 已设置到 $shell_rc。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
    fi
}

# 主菜单
function main_menu() {
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看Docker Compose日志"
    echo "3. 设置快捷键"
    read -p "请输入选项（1-3）: " option

    case $option in
    1) install_node ;;
    2) view_logs ;;
    3) check_and_set_alias ;;
    *) echo "无效选项。" && main_menu ;;
    esac
}

# 显示主菜单
main_menu
