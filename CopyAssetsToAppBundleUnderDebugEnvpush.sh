#!/bin/bash

# 检查当前构建配置是否为 DEBUG
if [ "$CONFIGURATION" != "Debug" ]; then
  echo "This script is only intended for DEBUG configuration. Skipping..."
  exit 0
fi

echo "🤪🤪🤪🤪🤪"

# 设置目标文件夹，这里使用了一些环境变量来构建目标路径
DESTINATION=$BUILT_PRODUCTS_DIR"/"$PRODUCT_NAME".app/"

# 使用 find 命令查找项目中所有的 PNG 文件，排除了指定的排除目录
find "$SRCROOT/$TARGETNAME/Assets.xcassets" -type f -name '*.png' \
  | grep -Fvf "$SRCROOT/exclude_paths.txt" \
  | xargs -I {} -P 4 cp {} $DESTINATION

# 退出脚本，表示成功完成
echo "🥳🥳🥳🥳🥳"
exit 0

