
#!/bin/bash

set -Eeuo pipefail

# =========================================================
# restart-web-vue 前端自动发布脚本
#
# 用法：
#   ./deploy-web.sh deploy
#   ./deploy-web.sh status
#   ./deploy-web.sh rollback
# =========================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/deploy-web.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误：找不到配置文件 $CONFIG_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

SSH_USER="${SSH_USER:-ubuntu}"
SSH_HOST="${SSH_HOST:-}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"
WEB_DIR="${WEB_DIR:-/var/www/restart-web}"
BACKUP_DIR="${BACKUP_DIR:-/var/www/restart-web-backups}"
KEEP_BACKUPS="${KEEP_BACKUPS:-5}"

if [ -z "$SSH_HOST" ]; then
    echo "错误：请在 deploy-web.conf 中配置 SSH_HOST"
    exit 1
fi

REMOTE="${SSH_USER}@${SSH_HOST}"

SSH_OPTIONS=(
    -p "$SSH_PORT"
    -o ConnectTimeout=10
    -o ServerAliveInterval=30
)

SCP_OPTIONS=(
    -P "$SSH_PORT"
    -o ConnectTimeout=10
)

if [ -n "$SSH_KEY" ]; then
    SSH_OPTIONS+=(-i "$SSH_KEY")
    SCP_OPTIONS+=(-i "$SSH_KEY")
fi

ssh_run() {
    ssh "${SSH_OPTIONS[@]}" "$REMOTE" "$@"
}

show_help() {
    cat <<'EOF'
用法：
  ./deploy-web.sh deploy     构建并发布前端
  ./deploy-web.sh status     检查 Nginx 和网站目录
  ./deploy-web.sh rollback   回滚到最近的历史版本
EOF
}

build_frontend() {
    echo
    echo "========== 1. 构建 Vue 前端 =========="

    cd "$SCRIPT_DIR"

    if ! command -v npm >/dev/null 2>&1; then
        echo "错误：没有找到 npm，请先安装 Node.js"
        exit 1
    fi

    if [ -f package-lock.json ]; then
        npm ci
    else
        npm install
    fi

    npm run build

    if [ ! -d "$SCRIPT_DIR/dist" ] ||
       [ -z "$(find "$SCRIPT_DIR/dist" -type f -print -quit)" ]; then
        echo "错误：dist 目录不存在或没有构建文件"
        exit 1
    fi

    echo "前端构建成功：$SCRIPT_DIR/dist"
}

deploy_frontend() {
    local stamp archive remote_tmp

    stamp="$(date '+%Y%m%d_%H%M%S')"
    archive="$(mktemp "${TMPDIR:-/tmp}/restart-web-${stamp}-XXXXXX.tar.gz")"
    remote_tmp="/tmp/restart-web-${stamp}-$$.tar.gz"

    trap 'rm -f "${archive:-}"' EXIT

    echo
    echo "========== 2. 打包 dist =========="

    tar -czf "$archive" -C "$SCRIPT_DIR/dist" .

    echo
    echo "========== 3. 检查服务器 =========="

    ssh_run "set -e; command -v nginx; sudo nginx -t"

    echo
    echo "========== 4. 上传前端文件 =========="

    scp "${SCP_OPTIONS[@]}" "$archive" "${REMOTE}:${remote_tmp}"

    echo
    echo "========== 5. 部署、检查 Nginx =========="

    ssh_run "sudo bash -s -- '$remote_tmp' '$WEB_DIR' '$BACKUP_DIR' '$KEEP_BACKUPS'" <<'REMOTE_SCRIPT'
set -Eeuo pipefail

REMOTE_TMP="$1"
WEB_DIR="$2"
BACKUP_DIR="$3"
KEEP_BACKUPS="$4"

PARENT_DIR="$(dirname "$WEB_DIR")"
STAMP="$(date '+%Y%m%d_%H%M%S')"
STAGE_DIR="${PARENT_DIR}/.restart-web-stage-${STAMP}-$$"
OLD_DIR="${BACKUP_DIR}/restart-web-${STAMP}"
HAD_OLD=0
DEPLOY_OK=0

rollback_on_error() {
    local code=$?

    if [ "$DEPLOY_OK" -eq 1 ]; then
        return
    fi

    trap - ERR
    echo "部署失败，正在尝试恢复旧版本……"

    rm -rf "$STAGE_DIR"

    if [ "$HAD_OLD" -eq 1 ] && [ -d "$OLD_DIR" ]; then
        rm -rf "$WEB_DIR"
        mv "$OLD_DIR" "$WEB_DIR"

        if nginx -t && systemctl reload nginx; then
            echo "旧版本已恢复，Nginx 配置检查和重载成功"
        else
            echo "严重错误：旧版本已恢复，但 Nginx 检查或重载失败"
            nginx -t || true
            systemctl status nginx --no-pager || true
        fi
    else
        echo "没有旧版本备份可恢复"
    fi

    rm -f "$REMOTE_TMP"
    exit "$code"
}
trap rollback_on_error ERR

if [ ! -s "$REMOTE_TMP" ]; then
    echo "错误：上传的压缩文件不存在或为空"
    false
fi

mkdir -p "$PARENT_DIR" "$BACKUP_DIR" "$STAGE_DIR"

# 仅解压到新目录，不直接覆盖正在服务的文件
tar -xzf "$REMOTE_TMP" -C "$STAGE_DIR"
rm -f "$REMOTE_TMP"

if [ -z "$(find "$STAGE_DIR" -type f -print -quit)" ]; then
    echo "错误：解压后没有网站文件"
    false
fi

# 确认首页存在
if [ ! -f "$STAGE_DIR/index.html" ]; then
    echo "错误：构建结果中没有 index.html"
    false
fi

# 备份旧网站目录
if [ -d "$WEB_DIR" ]; then
    mv "$WEB_DIR" "$OLD_DIR"
    HAD_OLD=1
    echo "旧版本已备份到：$OLD_DIR"
fi

# 新版本整体切换，避免逐个覆盖静态文件
mv "$STAGE_DIR" "$WEB_DIR"

# 公开静态文件读取权限
chmod -R a+rX "$WEB_DIR"

# 先验证 Nginx 配置，再重载
nginx -t
systemctl reload nginx

# 确认 Nginx 仍在运行
systemctl is-active --quiet nginx

DEPLOY_OK=1
trap - ERR

echo
echo "前端发布成功！"
echo "网站目录：$WEB_DIR"
echo "Nginx 配置检查和重载成功"

# 清理旧备份，仅保留最近 KEEP_BACKUPS 个版本
if [[ "$KEEP_BACKUPS" =~ ^[0-9]+$ ]]; then
    while IFS= read -r old_dir; do
        [ -n "$old_dir" ] || continue
        rm -rf -- "$old_dir"
    done < <(
        find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 \
            -type d -name 'restart-web-*' \
            -printf '%T@ %p\n' |
        sort -nr |
        awk -v keep="$KEEP_BACKUPS" '
            { count++; if (count > keep) { sub(/^[^ ]+ /, ""); print } }
        '
    )
fi

REMOTE_SCRIPT

    echo
    echo "========== 发布完成 =========="
}

show_status() {
    ssh_run "sudo nginx -t && sudo systemctl status nginx --no-pager && sudo ls -ld '$WEB_DIR' && sudo ls -l '$WEB_DIR/index.html'"
}

rollback_frontend() {
    echo "警告：将回滚到最近的历史版本。"
    printf "输入 YES 确认："
    read -r answer

    if [ "$answer" != "YES" ]; then
        echo "已取消"
        exit 0
    fi

    ssh_run "sudo bash -s -- '$WEB_DIR' '$BACKUP_DIR'" <<'REMOTE_ROLLBACK'
set -Eeuo pipefail

WEB_DIR="$1"
BACKUP_DIR="$2"
PARENT_DIR="$(dirname "$WEB_DIR")"

BACKUP_DIR_LATEST="$(
    find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 \
        -type d -name 'restart-web-*' \
        -printf '%T@ %p\n' |
    sort -nr |
    head -n 1 |
    sed 's/^[^ ]* //'
)"

if [ -z "$BACKUP_DIR_LATEST" ] || [ ! -d "$BACKUP_DIR_LATEST" ]; then
    echo "错误：没有找到可回滚的历史版本"
    exit 1
fi

STAMP="$(date '+%Y%m%d_%H%M%S')"
CURRENT_BACKUP="${BACKUP_DIR}/restart-web-before-rollback-${STAMP}"

# 先保存当前版本，便于再次恢复
if [ -d "$WEB_DIR" ]; then
    mv "$WEB_DIR" "$CURRENT_BACKUP"
fi

if ! mv "$BACKUP_DIR_LATEST" "$WEB_DIR"; then
    [ ! -d "$CURRENT_BACKUP" ] || mv "$CURRENT_BACKUP" "$WEB_DIR"
    exit 1
fi

if nginx -t && systemctl reload nginx &&
   systemctl is-active --quiet nginx; then
    echo "前端回滚成功：$BACKUP_DIR_LATEST"
else
    echo "回滚后 Nginx 检查或重载失败，尝试恢复回滚前的网站文件"

    rm -rf "$WEB_DIR"
    if [ -d "$CURRENT_BACKUP" ]; then
        mv "$CURRENT_BACKUP" "$WEB_DIR"
    fi

    nginx -t && systemctl reload nginx || true
    exit 1
fi
REMOTE_ROLLBACK
}

COMMAND="${1:-deploy}"

case "$COMMAND" in
    deploy)
        build_frontend
        deploy_frontend
        ;;
    status)
        show_status
        ;;
    rollback)
        rollback_frontend
        ;;
    -h|--help|help)
        show_help
        ;;
    *)
        echo "未知命令：$COMMAND"
        show_help
        exit 1
        ;;
esac
