#!/usr/bin/env bash
# ============================================================
# Mizuki 博客一键发布脚本
# 用法: bash scripts/quick-publish.sh <markdown文件路径> [分类] [标签1,标签2]
#
# 示例:
#   bash scripts/quick-publish.sh "笔记.md"
#   bash scripts/quick-publish.sh "笔记.md" "学习笔记" "国际金融,特里芬"
#   bash scripts/quick-publish.sh "笔记.md" "" "R,数据分析"
# ============================================================
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── 1. 参数解析 ──────────────────────────────────────────
INPUT_FILE="$1"
CATEGORY="${2:-}"
IFS=',' read -ra TAGS <<< "${3:-}"

if [ -z "$INPUT_FILE" ]; then
    echo -e "${RED}用法: bash scripts/quick-publish.sh <markdown文件> [分类] [标签1,标签2,...]${NC}"
    echo ""
    echo "示例:"
    echo "  bash scripts/quick-publish.sh \"D:/笔记/第六章_国际储备.md\""
    echo "  bash scripts/quick-publish.sh \"D:/笔记/第六章_国际储备.md\" \"学习笔记\" \"国际金融,特里芬难题\""
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}错误: 文件不存在 → $INPUT_FILE${NC}"
    exit 1
fi

# ── 2. 进入项目根目录 ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

POSTS_DIR="$PROJECT_DIR/src/content/posts"
BASENAME=$(basename "$INPUT_FILE")
# 中文文件名转英文连字符（基础转换）
SAFE_NAME=$(echo "$BASENAME" | sed 's/[[:space:]]/-/g' | sed 's/[^a-zA-Z0-9_.-]//g' | tr '[:upper:]' '[:lower:]' | sed 's/--*/-/g')
# 如果转换后为空或太短，用日期+序号
if [ -z "$SAFE_NAME" ] || [ "${#SAFE_NAME}" -lt 5 ]; then
    SAFE_NAME="post-$(date +%Y%m%d-%H%M%S).md"
fi
DEST_FILE="$POSTS_DIR/$SAFE_NAME"

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       Mizuki 博客一键发布工具                ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  源文件: ${YELLOW}$INPUT_FILE${NC}"
echo -e "  目标文件: ${YELLOW}$SAFE_NAME${NC}"
echo -e "  目标路径: ${YELLOW}$DEST_FILE${NC}"

# ── 3. 检查 frontmatter ──────────────────────────────────
echo ""
echo -e "${CYAN}[1/4]${NC} 检查 frontmatter..."

HAS_FRONTMATTER=false
if head -5 "$INPUT_FILE" | grep -q '^---$'; then
    HAS_FRONTMATTER=true
    echo -e "  ${GREEN}✓${NC} 已检测到 frontmatter"
    # 提取标题作为确认信息
    TITLE=$(sed -n '/^---$/,/^---$/p' "$INPUT_FILE" | grep '^title:' | head -1 | sed 's/^title:\s*//' | sed 's/^["'"'"']//;s/["'"'"']$//')
    if [ -n "$TITLE" ]; then
        echo -e "  文章标题: ${GREEN}$TITLE${NC}"
    fi
else
    echo -e "  ${RED}⚠ 未检测到 frontmatter！${NC}"
    echo ""
    echo -e "  ${YELLOW}frontmatter 是必填的，否则 Vercel 构建会失败。${NC}"
    echo -e "  至少需要包含 title 和 published 字段。"
    echo ""
    echo -e "  ${CYAN}现在输入基本信息帮你自动生成：${NC}"

    read -r -p "    文章标题: " TITLE_INPUT
    read -r -p "    发布日期 [$(date +%Y-%m-%d)]: " DATE_INPUT
    DATE_INPUT="${DATE_INPUT:-$(date +%Y-%m-%d)}"
    read -r -p "    文章摘要: " DESC_INPUT

    CAT_STR=""
    TAG_STR=""
    if [ -n "$CATEGORY" ]; then
        CAT_STR="category: $CATEGORY"
    fi
    if [ ${#TAGS[@]} -gt 0 ] && [ -n "${TAGS[0]}" ]; then
        TAG_LIST=""
        for t in "${TAGS[@]}"; do
            t=$(echo "$t" | xargs)  # trim
            [ -n "$t" ] && TAG_LIST="$TAG_LIST  - $t"$'\n'
        done
        TAG_STR="tags:"$'\n'"$TAG_LIST"
    fi

    # 生成临时文件（包含 frontmatter + 原文）
    TMP_FILE=$(mktemp)
    cat > "$TMP_FILE" << FRONTMATTER
---
title: ${TITLE_INPUT:-未命名文章}
published: $DATE_INPUT
description: ${DESC_INPUT:-}
$CAT_STR
$TAG_STR
draft: false
---

FRONTMATTER
    cat "$INPUT_FILE" >> "$TMP_FILE"
    INPUT_FILE="$TMP_FILE"
    echo -e "  ${GREEN}✓${NC} frontmatter 已自动生成"
fi

# ── 4. 复制文件到 posts 目录 ──────────────────────────────
echo ""
echo -e "${CYAN}[2/4]${NC} 复制文件到 posts 目录..."

# 检查是否会覆盖
if [ -f "$DEST_FILE" ]; then
    echo -e "  ${YELLOW}⚠ 目标文件已存在，将覆盖${NC}"
fi

cp "$INPUT_FILE" "$DEST_FILE"
echo -e "  ${GREEN}✓${NC} 文件已复制"

# ── 5. 确认提交 ──────────────────────────────────────────
echo ""
echo -e "${CYAN}[3/4]${NC} 准备提交到 GitHub..."

# 从标题生成 commit message
COMMIT_TITLE="${TITLE:-新文章}"
COMMIT_MSG="feat: add ${COMMIT_TITLE}"

echo ""
echo -e "  ${YELLOW}即将执行:${NC}"
echo -e "    git add ${SAFE_NAME}"
echo -e "    git commit -m \"${COMMIT_MSG}\""
echo -e "    git push origin master"
echo ""

read -r -p "  确认提交并推送? [Y/n] " CONFIRM
if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
    echo -e "  ${YELLOW}已取消。文件已复制到 $DEST_FILE，可稍后手动提交。${NC}"
    exit 0
fi

# ── 6. Git 提交和推送 ────────────────────────────────────
echo ""
echo -e "${CYAN}[4/4]${NC} 提交并推送..."

git add "$DEST_FILE"
git commit -m "$COMMIT_MSG"

echo -e "  ${GREEN}✓${NC} 已提交: ${COMMIT_MSG}"

echo ""
echo -e "  正在推送到 GitHub..."
if git push origin master 2>&1; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ 发布完成！                                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Vercel 将自动检测更新并构建部署。"
    echo -e "  稍后访问你的博客即可看到新文章。"
else
    echo ""
    echo -e "${RED}  ✗ 推送失败！请确认：${NC}"
    echo -e "    1. 是否开启了全局代理/梯子"
    echo -e "    2. 网络连接是否正常"
    echo -e "    3. 可以稍后手动执行: ${CYAN}git push origin master${NC}"
    exit 1
fi

# ── 清理临时文件 ──────────────────────────────────────────
if [ -n "$TMP_FILE" ] && [ -f "$TMP_FILE" ]; then
    rm "$TMP_FILE"
fi
