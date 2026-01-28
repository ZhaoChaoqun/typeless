import SwiftUI

/// 设置视图
struct SettingsView: View {
    @AppStorage("triggerKey") private var triggerKey = "fn"
    @AppStorage("modelSize") private var modelSize = "base"

    var body: some View {
        Form {
            Section("语音识别") {
                Picker("Whisper 模型", selection: $modelSize) {
                    Text("Tiny (最快)").tag("tiny")
                    Text("Base (推荐)").tag("base")
                    Text("Small (更准确)").tag("small")
                }
                .pickerStyle(.menu)

                Text("更大的模型识别更准确，但速度更慢")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("快捷键") {
                Text("长按 Fn 键开始录音")
                    .foregroundColor(.secondary)
            }

            Section("关于") {
                LabeledContent("版本", value: "1.0.0")
                LabeledContent("作者", value: "Typeless Team")
            }

            Section {
                Link("辅助功能设置", destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                Link("麦克风设置", destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            } header: {
                Text("权限")
            } footer: {
                Text("Typeless 需要辅助功能权限来监听全局按键，需要麦克风权限来录制语音。")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
    }
}

#Preview {
    SettingsView()
}
