#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

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

read -p "请输入Beacon Holskey RPC（如果你没有搭建的话，请输入:http://195.201.170.121:5052或者http://188.40.51.249:5052即可）链接: " l1_beacon_http

read -p "请输入Prover RPC 链接(目前可用任意选一个:http://kenz-prover.hekla.kzvn.xyz:9876或者http://hekla.stonemac65.xyz:9876): " prover_endpoints

read -p "请确认是否作为提议者（可选true或者false，目前prover 节点已经工作，请输入true，更新时间2024.4.26 15.30）: " enable_proposer

read -p "请输入EVM钱包私钥,不需要带0x: " l1_proposer_private_key

read -p "请输入EVM钱包地址: " l2_suggested_fee_recipient

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
sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${l1_beacon_http}|" .env
sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=${enable_proposer}|" .env
sed -i "s|L1_PROPOSER_PRIVATE_KEY=.*|L1_PROPOSER_PRIVATE_KEY=${l1_proposer_private_key}|" .env
sed -i "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${l2_suggested_fee_recipient}|" .env
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env


# 更新.env文件中的端口配置
sed -i "s|PORT_L2_EXECUTION_ENGINE_HTTP=.*|PORT_L2_EXECUTION_ENGINE_HTTP=${port_l2_execution_engine_http}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_WS=.*|PORT_L2_EXECUTION_ENGINE_WS=${port_l2_execution_engine_ws}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_METRICS=.*|PORT_L2_EXECUTION_ENGINE_METRICS=${port_l2_execution_engine_metrics}|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_P2P=.*|PORT_L2_EXECUTION_ENGINE_P2P=${port_l2_execution_engine_p2p}|" .env
sed -i "s|PORT_PROVER_SERVER=.*|PORT_PROVER_SERVER=${port_prover_server}|" .env
sed -i "s|PORT_PROMETHEUS=.*|PORT_PROMETHEUS=${port_prometheus}|" .env
sed -i "s|PORT_GRAFANA=.*|PORT_GRAFANA=${port_grafana}|" .env
sed -i "s|BLOCK_PROPOSAL_FEE=.*|BLOCK_PROPOSAL_FEE=30|" .env
sed -i 's/${PORT_L2_EXECUTION_ENGINE_P2P}:${PORT_L2_EXECUTION_ENGINE_P2P}/${PORT_L2_EXECUTION_ENGINE_P2P}:30303/g' docker-compose.yml
sed -i 's/${PORT_L2_EXECUTION_ENGINE_P2P}:${PORT_L2_EXECUTION_ENGINE_P2P}\/udp/${PORT_L2_EXECUTION_ENGINE_P2P}:30303\/udp/g' docker-compose.yml
sed -i "s|BOOT_NODES=.*|BOOT_NODES=enode://2f7ee605f84362671e7d7c6d47b69a3358b0d87e9ba4648befcae8b19453275ed19059db347c459384c1a3e5486419233c06bf6c4c6f489d81ace6f301a2a446@43.153.55.134:30303,enode://c067356146268d2855ad356c1ce36ba9f78c1633a72f9b7f686679c2ffe04bab6d24e48ef6eefb0e01aa00dff5024f7f94bc583da90b6027f40be4129bbbc5fd@43.153.90.191:30303,enode://acc2bdb6416feddff9734bee1e6de91e684e9df5aeb1d36698cc78b920600aed36a2871e4ad0cf4521afcdc2cde8e2cd410a57038767c356d4ce6c69b9107a5a@170.106.109.12:30303,enode://eb5079aae185d5d8afa01bfd2d349da5b476609aced2b57c90142556cf0ee4a152bcdd724627a7de97adfc2a68af5742a8f58781366e6a857d4bde98de6fe986@34.66.210.65:30303,enode://2294f526cbb7faa778192289c252307420532191438ce821d3c50232e019a797bda8c8f8541de0847e953bb03096123856935e32294de9814d15d120131499ba@34.72.186.213:30303,enode://4964fa273909ebcd21f6d0de4d49a5af8ee8c7309bdf7c6e11c1ba7ad434624bcad986bff17bbbb69fa61555902232acaa78f988b15f0498bb1bc5db6c217f3b@65.108.233.73:30306,enode://d8ecf4ea776f05d6cce6b8b53ef966d3d3bed05691dfd457bb6045a7ed6d340fa0bb39b228197dcd2f8657745a72dbe6eed01d81e8616aa32cc0946e5fadae51@5.42.102.190:30306|" .env

# 用户信息已配置完毕
echo "用户信息已配置完毕。"

# 升级所有已安装的包
sudo apt upgrade -y

# 安装基本组件
sudo apt install pkg-config curl build-essential libssl-dev libclang-dev ufw docker-compose-plugin -y

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

    # 安装 Docker compose 最新版本
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
docker compose version

# 验证 Docker Engine 安装是否成功
sudo docker run hello-world
# 应该能看到 hello-world 程序的输出

# 运行 Taiko 节点
docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
docker compose --profile proposer up -d

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
    cd #HOME
    cd simple-taiko-node
    docker compose logs -f --tail 20
}

# 更改常规配置
function change_option() {
cd #HOME
cd simple-taiko-node

read -p "请输入BlockPI holesky HTTP链接: " l1_endpoint_http

read -p "请输入BlockPI holesky WS链接: " l1_endpoint_ws

read -p "请输入Beacon Holskey RPC（如果你没有搭建的话，请输入:http://195.201.170.121:5052或者http://188.40.51.249:5052即可）链接: " l1_beacon_http

read -p "请输入Prover RPC 链接(目前可用任意选一个:http://kenz-prover.hekla.kzvn.xyz:9876或者http://hekla.stonemac65.xyz:9876): " prover_endpoints

read -p "请确认是否作为提议者（可选true或者false，目前prover 节点已经工作，请输入true，更新时间2024.4.26 15.30）: " enable_proposer

read -p "请确认是否关闭P2P同步（可选true或者false，请选择false开启）: " disable_p2p_sync

read -p "请输入EVM钱包私钥: " l1_proposer_private_key

read -p "请输入EVM钱包地址: " l2_suggested_fee_recipient

# 将用户输入的值写入.env文件
sed -i "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=${l1_endpoint_http}|" .env
sed -i "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=${l1_endpoint_ws}|" .env
sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${l1_beacon_http}|" .env
sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=${enable_proposer}|" .env
sed -i "s|L1_PROPOSER_PRIVATE_KEY=.*|L1_PROPOSER_PRIVATE_KEY=${l1_proposer_private_key}|" .env
sed -i "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${l2_suggested_fee_recipient}|" .env
sed -i "s|DISABLE_P2P_SYNC=.*|DISABLE_P2P_SYNC=${disable_p2p_sync}|" .env
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env


docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
docker compose --profile proposer up -d

}

function change_prover() {
cd #HOME
cd simple-taiko-node

read -p "请输入Prover RPC 链接(目前可用任意选一个:http://kenz-prover.hekla.kzvn.xyz:9876或者http://hekla.stonemac65.xyz:9876): " prover_endpoints

sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env

docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1

docker compose --profile proposer up -d

}

# 查看节点日志
function delete_new() {
    cd #HOME
    cd simple-taiko-node
    docker compose --profile l2_execution_engine down -v
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    cd #HOME
    rm -rf simple-taiko-node
}

function delete_old() {
    cd #HOME
    cd simple-taiko-node
    docker compose down -v
    cd #HOME
    rm -rf simple-taiko-node
}

function update_beacon_bootnode() {
    cd #HOME
    cd simple-taiko-node
    read -p "请输入Beacon Holskey RPC（如果你没有搭建的话，请输入:http://195.201.170.121:5052或者http://188.40.51.249:5052即可）链接: " l1_beacon_http
    sed -i "s|BOOT_NODES=.*|BOOT_NODES=enode://0b310c7dcfcf45ef32dde60fec274af88d52c7f0fb6a7e038b14f5f7bb7d72f3ab96a59328270532a871db988a0bcf57aa9258fa8a80e8e553a7bb5abd77c40d@167.235.249.45:30303,enode://500a10f3a8cfe00689eb9d41331605bf5e746625ac356c24235ff66145c2de454d869563a71efb3d2fb4bc1c1053b84d0ab6deb0a4155e7227188e1a8457b152@85.10.202.253:30303,enode://0b310c7dcfcf45ef32dde60fec274af88d52c7f0fb6a7e038b14f5f7bb7d72f3ab96a59328270532a871db988a0bcf57aa9258fa8a80e8e553a7bb5abd77c40d@167.235.249.45:30303,enode://500a10f3a8cfe00689eb9d41331605bf5e746625ac356c24235ff66145c2de454d869563a71efb3d2fb4bc1c1053b84d0ab6deb0a4155e7227188e1a8457b152@85.10.202.253:30303|" .env
    sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${l1_beacon_http}|" .env
    docker compose --profile l2_execution_engine down -v
    docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
    docker compose --profile proposer up -d
}


function change_L1RPC() {
cd #HOME
cd simple-taiko-node

read -p "请输入BlockPI holesky HTTP链接: " l1_endpoint_http

read -p "请输入BlockPI holesky WS链接: " l1_endpoint_ws

sed -i "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=${l1_endpoint_http}|" .env
sed -i "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=${l1_endpoint_ws}|" .env

docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
docker compose --profile proposer up -d

}

# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "=====================安装及常规修改功能========================="
    echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
    echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
    echo "节点社区 Discord 社群:https://discord.gg/GbMV5EcNWF"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    echo "3. 设置快捷键的功能"
    echo "4. 更改常规配置"
    echo "5. 更换prover rpc"
    echo "=======================卸载节点功能============================="
    echo "6. 卸载新测试网节点（所有数据清除）"
    echo "7. 卸载旧测试网节点（所有数据清除）"
    echo "=======================常规更新功能============================="
    echo "8. 更新Beacon rpc和加速节点"
    echo "9. 更换L1 holesky rpc"
    read -p "请输入选项（1-8）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) check_and_set_alias ;; 
    4) change_option ;; 
    5) change_prover ;; 
    6) delete_new ;; 
    7) delete_old ;; 
    8) update_beacon_bootnode ;; 
    9) change_L1RPC ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
