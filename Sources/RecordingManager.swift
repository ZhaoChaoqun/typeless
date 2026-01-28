import Foundation
import AVFoundation
import WhisperKit

/// 管理音频录制和语音识别
class RecordingManager {
    private var audioRecorder: AVAudioRecorder?
    private var whisperKit: WhisperKit?
    private var recordingURL: URL?
    private var isRecording = false

    init() {
        Task {
            await initializeWhisper()
        }
    }

    private func initializeWhisper() async {
        do {
            // 使用 base 模型，平衡速度和准确性
            // 对于中英混合，base 或 small 模型效果较好
            whisperKit = try await WhisperKit(model: "base")
            print("WhisperKit 初始化成功")
        } catch {
            print("WhisperKit 初始化失败: \(error)")
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("typeless_recording_\(UUID().uuidString).wav")

        guard let url = recordingURL else { return }

        // 配置录音设置 - Whisper 需要 16kHz 采样率
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
            print("开始录音: \(url.path)")
        } catch {
            print("录音启动失败: \(error)")
        }
    }

    func stopRecording(completion: @escaping (String?) -> Void) {
        guard isRecording, let recorder = audioRecorder else {
            completion(nil)
            return
        }

        recorder.stop()
        isRecording = false
        print("停止录音")

        guard let url = recordingURL else {
            completion(nil)
            return
        }

        // 异步进行语音识别
        Task {
            let text = await transcribe(audioURL: url)

            // 清理临时文件
            try? FileManager.default.removeItem(at: url)

            await MainActor.run {
                completion(text)
            }
        }
    }

    private func transcribe(audioURL: URL) async -> String? {
        guard let whisper = whisperKit else {
            print("WhisperKit 未初始化")
            return nil
        }

        do {
            let results = try await whisper.transcribe(audioPath: audioURL.path)

            // 合并所有转录结果
            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            print("转录结果: \(text)")
            return text.isEmpty ? nil : text
        } catch {
            print("转录失败: \(error)")
            return nil
        }
    }

    var isInitialized: Bool {
        whisperKit != nil
    }
}
