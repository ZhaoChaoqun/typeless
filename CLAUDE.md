# Nano Typeless 项目开发备忘

## GitHub 账号

本机有两个 GitHub 账号：
- `chaoqunzhao_microsoft` - 公司账号
- `ZhaoChaoqun` - 个人账号

**typeless 是个人项目**，使用 `gh` 命令时如果遇到权限错误，请先切换到个人账号：

```bash
gh auth switch -u ZhaoChaoqun
```

## Release 构建流程

构建 Release 版本后，需要重新签名才能在本地运行：

```bash
# 1. 构建 Release
xcodebuild -scheme Typeless -configuration Release -derivedDataPath build

# 2. 重新签名 dylib 文件
cd "build/Build/Products/Release/Nano Typeless.app/Contents/Frameworks"
codesign --force --sign - libsherpa-onnx-c-api.dylib libonnxruntime.1.17.1.dylib

# 3. 重新签名整个 app
codesign --force --sign - "build/Build/Products/Release/Nano Typeless.app"
```

原因：sherpa-onnx 的 dylib 文件 Team ID 与主程序不匹配，需要使用 ad-hoc 签名（`--sign -`）重新签名。

## Python 环境管理

统一使用 `uv` 管理 Python 环境和包：

```bash
# 安装包
uv pip install <package>

# 运行 Python 脚本
uv run python script.py
```

## ModelScope 模型管理

### 仓库地址

- 仓库 ID: `zhaochaoqun/sherpa-onnx-asr-models`
- 网页: https://modelscope.cn/models/zhaochaoqun/sherpa-onnx-asr-models

### 上传模型文件

使用 ModelScope SDK 直接上传，**不需要克隆整个仓库**：

```python
import os
from modelscope.hub.api import HubApi

api = HubApi()
api.login(os.environ['MODELSCOPE_TOKEN'])  # Token 存储在环境变量中
api.upload_file(
    path_or_fileobj='本地文件路径',
    path_in_repo='仓库中的文件名',
    repo_id='zhaochaoqun/sherpa-onnx-asr-models'
)
```

### 模型文件本地缓存

缓存路径: `~/.cache/typeless-models/`

上传模型前，先检查本地缓存是否存在：
1. 如果存在，直接使用本地文件
2. 如果不存在，从 GitHub 下载到缓存目录，再上传

目录结构：
```
~/.cache/typeless-models/
├── sherpa-onnx-sense-voice-funasr-nano-int8-2025-12-17.tar.bz2
├── sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2
├── sherpa-onnx-punct-ct-transformer-zh-en-vocab272727-2024-04-12-int8.tar.bz2
└── silero_vad.onnx
```

### 当前模型清单

| 模型 | 用途 | GitHub 源 |
|-----|------|----------|
| sherpa-onnx-sense-voice-funasr-nano-int8-2025-12-17 | FunASR Nano ASR | k2-fsa/sherpa-onnx |
| sherpa-onnx-streaming-paraformer-bilingual-zh-en | Streaming Paraformer ASR | k2-fsa/sherpa-onnx |
| sherpa-onnx-punct-ct-transformer-zh-en-vocab272727-2024-04-12-int8 | CT-Transformer 标点模型 (INT8) | k2-fsa/sherpa-onnx |
| silero_vad.onnx | VAD 语音活动检测 | k2-fsa/sherpa-onnx |
