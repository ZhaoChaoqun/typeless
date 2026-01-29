#!/bin/bash

# 设置 Sherpa-ONNX xcframework
# 此脚本下载并设置 Sherpa-ONNX 用于 macOS

set -e

SHERPA_VERSION="v1.12.23"
DOWNLOAD_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/${SHERPA_VERSION}/sherpa-onnx-${SHERPA_VERSION}-macos-xcframework-static.tar.bz2"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORKS_DIR="${SCRIPT_DIR}/Frameworks"

echo "=== 设置 Sherpa-ONNX for macOS ==="

# 创建 Frameworks 目录
mkdir -p "${FRAMEWORKS_DIR}"

# 检查是否已下载
if [ -d "${FRAMEWORKS_DIR}/sherpa-onnx.xcframework" ]; then
    echo "Sherpa-ONNX xcframework 已存在，跳过下载"
    exit 0
fi

echo "下载 Sherpa-ONNX ${SHERPA_VERSION}..."
TEMP_FILE=$(mktemp)
curl -L -o "${TEMP_FILE}" "${DOWNLOAD_URL}"

echo "解压 xcframework..."
tar -xjf "${TEMP_FILE}" -C "${FRAMEWORKS_DIR}"

# 清理临时文件
rm "${TEMP_FILE}"

echo "=== 设置完成 ==="
echo "xcframework 位置: ${FRAMEWORKS_DIR}"
echo ""
echo "请将以下 xcframework 添加到 Xcode 项目:"
echo "  - sherpa-onnx.xcframework"
