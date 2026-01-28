# Typeless

一个 Mac 原生语音输入工具，长按 Fn 键说话，松开后自动将语音转换为文字并插入到光标位置。

## 功能特点

- 🎤 长按 Fn 键开始录音，松开即转文字
- 🔒 本地运行 Whisper 模型，保护隐私
- 🌐 支持中英文混合输入
- ⚡ 菜单栏常驻，快速启动

## 系统要求

- macOS 14.0+
- Apple Silicon (M1/M2/M3) 或 Intel Mac

## 构建

```bash
# 使用 Xcode 打开
open Typeless.xcodeproj

# 或使用命令行构建
xcodebuild -project Typeless.xcodeproj -scheme Typeless build
```

## 权限设置

首次运行需要授予以下权限：

1. **麦克风权限** - 用于录制语音
2. **辅助功能权限** - 用于监听全局快捷键

## 使用方法

1. 启动 Typeless，它会出现在菜单栏
2. 长按 Fn 键开始说话
3. 松开 Fn 键，等待语音转文字
4. 文字会自动插入到当前光标位置

## 技术栈

- Swift / SwiftUI
- WhisperKit (本地语音识别)
- AVFoundation (音频录制)
- CGEvent (全局按键监听和文字插入)

## License

MIT
