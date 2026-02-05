import Foundation
import AVFoundation

/// 管理音频录制和语音识别
class RecordingManager {
    static let shared = RecordingManager()

    private var audioEngine: AVAudioEngine?
    private var offlineRecognizer: SherpaOnnxRecognizer?       // FunASR Nano
    private var onlineRecognizer: SherpaOnnxOnlineRecognizer?  // Streaming Paraformer
    private var vad: SherpaOnnxVAD?
    private var isRecording = false
    private var isInitializing = false

    /// 当前选择的 ASR 模型
    private(set) var currentModel: ASRModelType {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: "selectedASRModel"),
               let model = ASRModelType(rawValue: rawValue) {
                return model
            }
            return .funasrNano
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedASRModel")
        }
    }

    /// 部分识别结果回调
    var onPartialResult: ((String) -> Void)?
    /// 累积的识别文字
    private var accumulatedText: String = ""
    /// 上一个语音段的结束时间（用于计算停顿时长）
    private var lastSegmentEndTime: Float = 0
    /// 用于识别的队列
    private let recognitionQueue = DispatchQueue(label: "com.typeless.recognition", qos: .userInitiated)

    // MARK: - 标点符号常量
    private static let questionWords: Set<Character> = ["吗", "呢", "吧", "么", "嘛"]
    private static let exclamationWords: Set<Character> = ["哇", "耶", "啦"]
    private static let punctuationSet: Set<Character> = ["，", "。", "！", "？", "、", "；"]

    init() {
        Task { await initializeRecognizer() }
    }

    /// 切换 ASR 模型
    func switchModel(to model: ASRModelType) async {
        guard model != currentModel else { return }
        currentModel = model
        await initializeRecognizer()
    }

    private func initializeRecognizer() async {
        guard !isInitializing else { return }
        isInitializing = true
        defer { isInitializing = false }

        print("========== 开始加载语音识别模型 (\(currentModel.displayName)) ==========")

        // 清理旧的识别器
        offlineRecognizer = nil
        onlineRecognizer = nil
        vad = nil

        switch currentModel {
        case .funasrNano:
            await initializeFunASR()
        case .streamingParaformer:
            await initializeStreamingParaformer()
        }
    }

    /// 初始化 FunASR Nano（需要 VAD）
    private func initializeFunASR() async {
        guard SherpaOnnxManager.shared.isFunASRModelDownloaded(),
              let paths = SherpaOnnxManager.shared.getFunASRModelPath() else {
            print("⚠️ FunASR Nano 模型未下载")
            return
        }

        offlineRecognizer = SherpaOnnxRecognizer(modelPath: paths.modelPath, tokensPath: paths.tokensPath)

        if offlineRecognizer != nil {
            print("========== FunASR Nano 模型加载成功 ==========")
        } else {
            print("========== FunASR Nano 模型加载失败 ==========")
            return
        }

        // 初始化 VAD（FunASR 需要）
        await initializeVAD()
    }

    /// 初始化 Streaming Paraformer（无需 VAD）
    private func initializeStreamingParaformer() async {
        guard SherpaOnnxManager.shared.isStreamingParaformerDownloaded(),
              let paths = SherpaOnnxManager.shared.getStreamingParaformerPath() else {
            print("⚠️ Streaming Paraformer 模型未下载")
            return
        }

        onlineRecognizer = SherpaOnnxOnlineRecognizer(
            encoderPath: paths.encoderPath,
            decoderPath: paths.decoderPath,
            tokensPath: paths.tokensPath
        )

        if onlineRecognizer != nil {
            print("========== Streaming Paraformer 模型加载成功 ==========")
        } else {
            print("========== Streaming Paraformer 模型加载失败 ==========")
        }
        // Streaming Paraformer 不需要 VAD
    }

    private func initializeVAD() async {
        // 先检查 VAD 模型是否存在
        if let vadPath = SherpaOnnxManager.shared.getVADModelPath() {
            vad = SherpaOnnxVAD(modelPath: vadPath)
            if vad != nil {
                print("========== VAD 加载成功 ==========")
            }
        } else {
            print("⚠️ VAD 模型未下载，正在下载...")
            // 异步下载 VAD 模型
            await withCheckedContinuation { continuation in
                SherpaOnnxManager.shared.downloadVADModel(progress: { progress in
                    print("[VAD] \(progress)")
                }, completion: { [weak self] success, error in
                    if success, let vadPath = SherpaOnnxManager.shared.getVADModelPath() {
                        self?.vad = SherpaOnnxVAD(modelPath: vadPath)
                        print("========== VAD 下载并加载成功 ==========")
                    } else {
                        print("⚠️ VAD 下载失败: \(error ?? "未知错误")")
                    }
                    continuation.resume()
                })
            }
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        // 重置状态
        accumulatedText = ""
        lastSegmentEndTime = 0

        // 根据模型类型重置
        switch currentModel {
        case .funasrNano:
            vad?.reset()
        case .streamingParaformer:
            // reset() 已在 stopRecording 中调用，无需额外操作
            break
        }

        // 创建音频引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // 目标格式：16kHz, mono, float32
        let targetSampleRate: Double = 16000
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetSampleRate, channels: 1, interleaved: false) else {
            print("无法创建目标音频格式")
            return
        }

        // 创建格式转换器
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            print("无法创建音频转换器")
            return
        }

        // 安装音频 tap
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
        }

        do {
            try audioEngine.start()
            isRecording = true
            print("开始流式录音 (\(currentModel.displayName))")
        } catch {
            print("启动音频引擎失败: \(error)")
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat) {
        // 计算输出缓冲区大小
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else { return }

        // 转换音频格式
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("音频转换错误: \(error)")
            return
        }

        // 提取浮点样本
        guard let floatData = outputBuffer.floatChannelData else { return }
        let samples = Array(UnsafeBufferPointer(start: floatData[0], count: Int(outputBuffer.frameLength)))

        // 根据模型类型处理
        switch currentModel {
        case .funasrNano:
            processWithVAD(samples: samples)
        case .streamingParaformer:
            processWithStreaming(samples: samples)
        }
    }

    /// 使用 VAD 分段处理（FunASR Nano）
    private func processWithVAD(samples: [Float]) {
        guard let vad = vad else { return }

        // 送入 VAD
        vad.acceptWaveform(samples: samples)

        // 检查是否有完整的语音段
        while vad.hasSegment() {
            if let segment = vad.popSegmentWithTime() {
                recognitionQueue.async { [weak self] in
                    self?.transcribeSegment(segment)
                }
            }
        }
    }

    /// 使用流式识别（Streaming Paraformer）
    private func processWithStreaming(samples: [Float]) {
        guard let recognizer = onlineRecognizer else { return }

        // 送入流式识别器
        recognizer.acceptWaveform(samples: samples)

        // 检查是否可以解码
        while recognizer.isReady() {
            recognizer.decode()
        }

        // 获取识别结果
        let text = recognizer.getResult()
        if !text.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.accumulatedText = text
                self?.onPartialResult?(text)
            }
        }
    }

    private func transcribeSegment(_ segment: SpeechSegment) {
        guard let recognizer = offlineRecognizer else { return }

        if let text = recognizer.transcribe(samples: segment.samples) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // 计算与上一段的停顿时长
                let pauseDuration = self.lastSegmentEndTime > 0 ? segment.startTime - self.lastSegmentEndTime : 0
                self.lastSegmentEndTime = segment.endTime

                // 智能拼接文字（带标点）
                self.accumulatedText = self.mergeTexts(self.accumulatedText, text, pauseDuration: pauseDuration)

                print(">>> 分段识别结果: \(text)")
                print(">>> 停顿时长: \(pauseDuration)秒")
                print(">>> 累积文字: \(self.accumulatedText)")

                // 通知 UI 更新
                self.onPartialResult?(self.accumulatedText)
            }
        }
    }

    /// 根据文本内容和停顿时长决定标点
    private func determinePunctuation(text: String, pauseDuration: Float) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let lastChar = trimmed.last else { return "" }

        // 疑问词检测
        if Self.questionWords.contains(lastChar) {
            return "？"
        }

        // 感叹词检测
        if Self.exclamationWords.contains(lastChar) {
            return "！"
        }

        // 根据停顿时长决定
        return pauseDuration >= 1.0 ? "。" : "，"
    }

    /// 拼接文字（带智能标点）
    private func mergeTexts(_ existing: String, _ new: String, pauseDuration: Float) -> String {
        if existing.isEmpty {
            return new
        }
        let punctuation = determinePunctuation(text: existing, pauseDuration: pauseDuration)
        return existing + punctuation + new
    }

    /// 在文本末尾添加最终标点
    private func addFinalPunctuation(_ text: String) -> String {
        if let last = text.last, Self.punctuationSet.contains(last) {
            return text
        }

        // 检查是否应该用问号
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let lastChar = trimmed.last, Self.questionWords.contains(lastChar) {
            return text + "？"
        }

        return text + "。"
    }

    func stopRecording(completion: @escaping (String?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }

        // 停止音频引擎
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        print("停止录音")

        // 根据模型类型处理
        switch currentModel {
        case .funasrNano:
            stopRecordingFunASR(completion: completion)
        case .streamingParaformer:
            stopRecordingStreaming(completion: completion)
        }
    }

    /// 停止 FunASR 录音（处理 VAD 剩余音频）
    private func stopRecordingFunASR(completion: @escaping (String?) -> Void) {
        // 刷新 VAD，处理剩余音频
        vad?.flush()

        // 处理剩余的语音段
        recognitionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            while self.vad?.hasSegment() == true {
                if let segment = self.vad?.popSegmentWithTime() {
                    if let text = self.offlineRecognizer?.transcribe(samples: segment.samples) {
                        DispatchQueue.main.sync {
                            // 计算停顿时长
                            let pauseDuration = self.lastSegmentEndTime > 0 ? segment.startTime - self.lastSegmentEndTime : 0
                            self.lastSegmentEndTime = segment.endTime
                            // 智能拼接文字（带标点）
                            self.accumulatedText = self.mergeTexts(self.accumulatedText, text, pauseDuration: pauseDuration)
                        }
                    }
                }
            }

            // 返回最终结果（添加末尾标点）
            var finalText: String? = nil
            if !self.accumulatedText.isEmpty {
                finalText = self.addFinalPunctuation(self.accumulatedText)
            }
            DispatchQueue.main.async {
                print(">>> 最终识别结果: \(finalText ?? "（无）")")
                completion(finalText)
            }
        }
    }

    /// 停止 Streaming Paraformer 录音
    private func stopRecordingStreaming(completion: @escaping (String?) -> Void) {
        guard let recognizer = onlineRecognizer else {
            completion(nil)
            return
        }

        // 注入 0.3 秒静音（4800 samples @ 16kHz）触发剩余帧解码
        let silencePadding = [Float](repeating: 0.0, count: 4800)
        recognizer.acceptWaveform(samples: silencePadding)

        // 解码所有剩余帧
        while recognizer.isReady() {
            recognizer.decode()
        }

        // 获取最终结果
        let text = recognizer.getResult()

        // 重置流状态（为下次录音准备）
        recognizer.reset()

        var finalText: String? = nil
        if !text.isEmpty {
            finalText = addFinalPunctuation(text)
        }
        print(">>> 最终识别结果: \(finalText ?? "（无）")")
        completion(finalText)
    }

    var isInitialized: Bool {
        switch currentModel {
        case .funasrNano:
            return offlineRecognizer != nil
        case .streamingParaformer:
            return onlineRecognizer != nil
        }
    }

    /// 重新加载模型（下载完成后调用）
    func reloadModel() {
        offlineRecognizer = nil
        onlineRecognizer = nil
        vad = nil
        Task { await initializeRecognizer() }
    }
}
