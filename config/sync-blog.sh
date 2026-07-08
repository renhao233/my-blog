#!/bin/bash
# ============================================================
#  sync-blog.sh — 从 GitHub 拉取最新文章，更新博客
# ============================================================
#  用法：bash config/sync-blog.sh
#  效果：git pull → 重新生成 posts.json → 首页自动更新
# ============================================================

set -e

# 定位博客根目录
BLOG_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BLOG_DIR"

# 拉取最新代码
echo "📥 git pull..."
git pull origin master

# 重新生成文章索引
echo "📋 重新生成 posts.json..."
bash config/build-posts.sh

echo "✅ 博客已更新"