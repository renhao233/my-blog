#!/bin/bash
# ============================================================
#  build-posts.sh — 扫描 posts/ 目录下的 .md 文件，生成 posts.json
# ============================================================
#  用法：bash config/build-posts.sh
#  效果：读取 posts/*.md → 生成 posts.json → 首页自动更新
#
#  每篇 .md 文件头部需要用 HTML 注释声明元数据，格式如下：
#    <!-- title: 文章标题 -->
#    <!-- date: 2026-07-05 -->
#    <!-- excerpt: 一句话摘要 -->
#    <!-- keywords: Rust, 编程语言, 学习笔记    （可选，SEO 关键词） -->
#    <!-- image: assets/rust-logo.png           （可选，OG/Twitter 配图） -->
#    <!-- tags: Rust, 编程                      （可选，文章标签） -->
# ============================================================

# 遇到错误立即退出，避免半成品
set -e

# ----------------------------------------------------------
# 第一步：确定路径
# ----------------------------------------------------------
# $0 是脚本自身的路径（比如 ./config/build-posts.sh）
# dirname 拿掉文件名，得到 ./config
# cd 进去再 .. 回到博客根目录
# pwd 输出绝对路径，存到 BLOG_DIR
BLOG_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 文章目录和输出文件，都基于博客根目录
POSTS_DIR="$BLOG_DIR/posts"      # 比如 /home/ubuntu/my-blog/posts
OUTPUT="$BLOG_DIR/posts.json"    # 比如 /home/ubuntu/my-blog/posts.json

# ----------------------------------------------------------
# 第二步：开始写 JSON 文件，先输出开头的 "["
# ----------------------------------------------------------
echo "[" > "$OUTPUT"            # > 覆盖写入，文件内容变成 "["
first=true                      # 标记：是否是第一篇文章（控制逗号）

# ----------------------------------------------------------
# 第三步：遍历 posts/ 下每一个 .md 文件
# ----------------------------------------------------------
for md in $(find "$POSTS_DIR" -name "*.md" | sort); do

  [ -f "$md" ] || continue

  slug=$(echo "$md" | sed "s|^$POSTS_DIR/||; s|\.md$||")

  # ----------------------------------------------------------
  # 从 .md 文件头部提取元数据
  # ----------------------------------------------------------
  # grep -oP 用 Perl 正则匹配，只输出匹配到的部分
  # \K 表示"从这里开始算匹配结果"，前面的是定位条件不输出
  # 比如匹配 <!-- title: 我的文章 --> 只输出 "我的文章"
  # sed 去掉末尾多余空格
  title=$(grep -oP '<!--\s*title:\s*\K.*?(?=\s*-->)' "$md" | head -1 | sed 's/[[:space:]]*$//')
  date=$(grep -oP '<!--\s*date:\s*\K.*?(?=\s*-->)' "$md" | head -1 | sed 's/[[:space:]]*$//')
  excerpt=$(grep -oP '<!--\s*excerpt:\s*\K.*?(?=\s*-->)' "$md" | head -1 | sed 's/[[:space:]]*$//')
  keywords=$(grep -oP '<!--\s*keywords:\s*\K.*?(?=\s*-->)' "$md" | head -1 | sed 's/[[:space:]]*$//')
  image=$(grep -oP '<!--\s*image:\s*\K.*?(?=\s*-->)' "$md" | head -1 | sed 's/[[:space:]]*$//')
  tags=$(grep -oP '<!--\s*tags:\s*\K.*?(?=\s*-->)' "$md" | head -1 | sed 's/[[:space:]]*$//')

  # 如果没有写 title，就用文件名当标题
  [ -z "$title" ] && title="$slug"

  # ----------------------------------------------------------
  # 输出 JSON 条目
  # ----------------------------------------------------------
  # 不是第一篇文章时，先输出逗号分隔上一篇文章
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$OUTPUT"       # >> 追加写入
  fi

  # heredoc 方式写入一条 JSON 记录
  cat >> "$OUTPUT" << EOF
  { "slug": "$slug", "title": "$title", "date": "$date", "excerpt": "$excerpt", "keywords": "$keywords", "image": "$image", "tags": "$tags" }
EOF
done

# ----------------------------------------------------------
# 第四步：收尾 JSON，输出结尾的 "]"
# ----------------------------------------------------------
echo "" >> "$OUTPUT"
echo "]" >> "$OUTPUT"

# ----------------------------------------------------------
# 第五步：按日期降序排序（最新的文章排最前面）
# ----------------------------------------------------------
# 用 Python 读取 JSON → 按 date 字段降序排列 → 写回文件
python3 -c "
import json
with open('$OUTPUT') as f:
    posts = json.load(f)
posts.sort(key=lambda p: p.get('date', ''), reverse=True)
with open('$OUTPUT', 'w') as f:
    json.dump(posts, f, ensure_ascii=False, indent=2)
"

# ----------------------------------------------------------
# 完成！输出统计
# ----------------------------------------------------------
echo "✓ posts.json 已生成 ($(python3 -c "import json; print(len(json.load(open('$OUTPUT'))))") 篇文章)"