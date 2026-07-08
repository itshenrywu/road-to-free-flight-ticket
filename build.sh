#!/usr/bin/env bash
#
# build.sh — 把 data/history.csv 的內容塞進 index.html，
# 讓頁面直接用內嵌資料，不需要再讀取 API / fetch CSV。
#
# index.html 內以下列標記包住的區塊會被自動覆寫（idempotent，可重複執行）：
#   // >>> BUILD:CSV ... >>>
#   const CSV_DATA = `...`
#   // <<< BUILD:CSV <<<

set -euo pipefail

cd "$(dirname "$0")"

CSV="data/history.csv"
HTML="index.html"
BEGIN="// >>> BUILD:CSV"
END="// <<< BUILD:CSV"

[ -f "$CSV" ]  || { echo "找不到 $CSV" >&2; exit 1; }
[ -f "$HTML" ] || { echo "找不到 $HTML" >&2; exit 1; }

grep -q "$BEGIN" "$HTML" || { echo "$HTML 內找不到 BUILD:CSV 標記" >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk -v csv="$CSV" -v begin="$BEGIN" -v end="$END" '
  index($0, begin) {
    print
    # 取得標記行的縮排，讓插入的內容對齊
    match($0, /^[ \t]*/)
    pad = substr($0, 1, RLENGTH)
    print pad "const CSV_DATA = `"
    while ((getline line < csv) > 0) print line
    close(csv)
    print "`"
    skip = 1
    next
  }
  index($0, end) { skip = 0 }
  !skip { print }
' "$HTML" > "$tmp"

mv "$tmp" "$HTML"
trap - EXIT

echo "已將 $CSV ($(grep -c . "$CSV") 筆) 塞進 $HTML"
