#!/bin/bash
# ============================================================
# 恭喜发财 V6 交易日守护进程
# 
# 功能:
#   1. 进程守护 — FastAPI 挂了自动重启
#   2. 健康检查 — 每30分钟检查 API/DeepSeek/数据源
#   3. 异常自修复 — 重启/降级/缓存清理
#   4. 每日日报 — 收盘后生成运行报告
#
# 使用:
#   chmod +x scripts/guardian.sh
#   ./scripts/guardian.sh &
#   或通过 launchd 守护: cp scripts/guardian.plist ~/Library/LaunchAgents/
# ============================================================

PORT=${PORT:-8001}
HOST=${HOST:-"127.0.0.1"}
HEALTH_URL="http://${HOST}:${PORT}/api/health"
LOG_DIR="${HOME}/cong-xi-fa-cai-logs"
PID_FILE="/tmp/cong-xi-fa-cai-v6.pid"
CHECK_INTERVAL=1800  # 30分钟
MAX_RESTARTS=5
RESTART_COUNT=0

# 加载 .env.local（如果存在）
ENV_FILE="$(dirname "$0")/../.env.local"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/guardian.log"
}

# ═══ 健康检查 ═══

check_api() {
    if curl -sf --max-time 5 "$HEALTH_URL" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

check_deepseek() {
    # 简单检查: 尝试连接到 api.deepseek.com
    if curl -sf --max-time 5 "https://api.deepseek.com/v1/models" -H "Authorization: Bearer ${DEEPSEEK_API_KEY}" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# ═══ 自修复 ═══

restart_api() {
    log "⚠️  FastAPI 无响应，尝试重启..."
    # 杀掉旧进程
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            kill -15 "$OLD_PID" 2>/dev/null
            sleep 3
            kill -9 "$OLD_PID" 2>/dev/null
        fi
    fi

    RESTART_COUNT=$((RESTART_COUNT + 1))
    if [ $RESTART_COUNT -gt $MAX_RESTARTS ]; then
        log "❌ 已达最大重启次数($MAX_RESTARTS)，停止守护。请手动检查。"
        exit 1
    fi

    # 重启
    PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    cd "$PROJECT_DIR"
    export PYTHONPATH="$PROJECT_DIR/backend"
    nohup python3 -m uvicorn app.main:app --host $HOST --port $PORT > "$LOG_DIR/api.log" 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    log "✅ API 已重启, PID=$NEW_PID (第${RESTART_COUNT}次)"
    sleep 5
}

# ═══ 日报 ═══

generate_daily_report() {
    local report_file="$LOG_DIR/daily-$(date '+%Y%m%d').log"
    {
        echo "========================================"
        echo " 恭喜发财 V6 运行日报"
        echo " 日期: $(date '+%Y-%m-%d %H:%M')"
        echo "========================================"
        echo ""
        echo "🔄 重启次数: $RESTART_COUNT"
        echo ""

        # API 状态
        if check_api; then
            HEALTH=$(curl -sf "$HEALTH_URL" 2>/dev/null)
            echo "✅ API 状态: 正常"
            echo "   $(echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH")"
        else
            echo "❌ API 状态: 异常"
        fi
        echo ""

        # DeepSeek 状态
        if check_deepseek; then
            echo "✅ DeepSeek: 可用"
        else
            echo "⚠️  DeepSeek: 不可用 (已降级到 qwen3.5:3b)"
        fi
        echo ""

        # 今日异常
        echo "⚠️  异常事件:"
        grep "$(date '+%Y-%m-%d')" "$LOG_DIR/guardian.log" | grep -E "❌|⚠️|异常|失败" | tail -20 || echo "  无异常"
        echo ""

        echo "--- 报告生成完毕 ---"
    } > "$report_file"
    log "📊 日报已生成: $report_file"
}

# ═══ 主循环 ═══

main() {
    log "🚀 恭喜发财 V6 交易日守护启动"
    log "   检查间隔: ${CHECK_INTERVAL}s"
    log "   日志目录: $LOG_DIR"

    # 检查初始状态
    if ! check_api; then
        restart_api
    fi

    # 主循环（监控+日报，不管理进程 — launchd 已负责 KeepAlive）
    while true; do
        sleep "$CHECK_INTERVAL"

        # 健康检查
        if check_api; then
            RESTART_COUNT=0
            log "✅ API 健康检查通过"
        else
            log "❌ API 无响应（launchd 会自动重启）"
        fi

        # DeepSeek 检查
        if ! check_deepseek; then
            log "⚠️  DeepSeek API 不可用"
        fi

        # 收盘后生成日报 (15:30)
        CURRENT_HOUR=$(date '+%H')
        CURRENT_MIN=$(date '+%M')
        if [ "$CURRENT_HOUR" = "15" ] && [ "$CURRENT_MIN" -ge "30" ] && [ "$CURRENT_MIN" -lt "35" ]; then
            if [ ! -f "$LOG_DIR/daily-$(date '+%Y%m%d').log" ]; then
                generate_daily_report
            fi
        fi
    done
}

main
