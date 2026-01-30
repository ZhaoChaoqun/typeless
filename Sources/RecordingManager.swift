import Foundation
import AVFoundation

/// 管理音频录制和语音识别
class RecordingManager {
    static let shared = RecordingManager()

    private var audioRecorder: AVAudioRecorder?
    private var recognizer: SherpaOnnxRecognizer?
    private var recordingURL: URL?
    private var isRecording = false
    private var isInitializing = false

    init() {
        Task { await initializeRecognizer() }
    }

    private func initializeRecognizer() async {
        guard !isInitializing else { return }
        isInitializing = true
        defer { isInitializing = false }

        print("========== 开始加载语音识别模型 ==========")

        guard SherpaOnnxManager.shared.isModelDownloaded(),
              let paths = SherpaOnnxManager.shared.getModelPath() else {
            print("⚠️ 模型未下载")
            return
        }

        recognizer = SherpaOnnxRecognizer(modelPath: paths.modelPath, tokensPath: paths.tokensPath)

        if recognizer != nil {
            print("========== 模型加载成功 ==========")
        } else {
            print("========== 模型加载失败 ==========")
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("typeless_recording_\(UUID().uuidString).wav")

        guard let url = recordingURL else { return }

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

        Task {
            let text = await transcribe(audioURL: url)
            try? FileManager.default.removeItem(at: url)
            await MainActor.run { completion(text) }
        }
    }

    private func transcribe(audioURL: URL) async -> String? {
        while isInitializing {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        guard let recognizer = recognizer else {
            print(">>> 识别器未初始化")
            return nil
        }

        print(">>> 开始转录...")
        let text = recognizer.transcribe(audioURL: audioURL)
        if let text = text {
            print("转录结果: \(text)")
        }
        return text
    }

    var isInitialized: Bool {
        return recognizer != nil
    }

    /// 重新加载模型（下载完成后调用）
    func reloadModel() {
        recognizer = nil
        Task { await initializeRecognizer() }
    }
}
