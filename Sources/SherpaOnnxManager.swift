import Foundation

/// Sherpa-ONNX 语音识别管理器
/// 支持 Paraformer 和 SenseVoice 模型
class SherpaOnnxManager {
    static let shared = SherpaOnnxManager()

    /// 模型存储根目录
    private let modelsDirectory: URL = {
        let documentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/typeless/models")
        try? FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        return documentsPath
    }()

    /// Paraformer 模型信息
    struct ParaformerModel {
        static let modelName = "sherpa-onnx-paraformer-zh-2024-03-09"
        static let downloadURL = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-paraformer-zh-2024-03-09.tar.bz2"

        let modelPath: String
        let tokensPath: String
    }

    /// SenseVoice 模型信息
    struct SenseVoiceModel {
        static let modelName = "sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17"
        static let downloadURL = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17.tar.bz2"

        let modelPath: String
        let tokensPath: String
    }

    /// 获取 Paraformer 模型路径
    func getParaformerModelPath() -> ParaformerModel? {
        let modelDir = modelsDirectory.appendingPathComponent(ParaformerModel.modelName)
        let modelPath = modelDir.appendingPathComponent("model.int8.onnx")
        let tokensPath = modelDir.appendingPathComponent("tokens.txt")

        guard FileManager.default.fileExists(atPath: modelPath.path),
              FileManager.default.fileExists(atPath: tokensPath.path) else {
            return nil
        }

        return ParaformerModel(modelPath: modelPath.path, tokensPath: tokensPath.path)
    }

    /// 获取 SenseVoice 模型路径
    func getSenseVoiceModelPath() -> SenseVoiceModel? {
        let modelDir = modelsDirectory.appendingPathComponent(SenseVoiceModel.modelName)
        let modelPath = modelDir.appendingPathComponent("model.int8.onnx")
        let tokensPath = modelDir.appendingPathComponent("tokens.txt")

        guard FileManager.default.fileExists(atPath: modelPath.path),
              FileManager.default.fileExists(atPath: tokensPath.path) else {
            return nil
        }

        return SenseVoiceModel(modelPath: modelPath.path, tokensPath: tokensPath.path)
    }

    /// 检查模型是否已下载
    func isModelDownloaded(_ modelId: String) -> Bool {
        switch modelId {
        case "paraformer":
            return getParaformerModelPath() != nil
        case "sensevoice-small":
            return getSenseVoiceModelPath() != nil
        default:
            return false
        }
    }

    /// 获取模型目录
    func getModelDirectory(for modelId: String) -> URL {
        switch modelId {
        case "paraformer":
            return modelsDirectory.appendingPathComponent(ParaformerModel.modelName)
        case "sensevoice-small":
            return modelsDirectory.appendingPathComponent(SenseVoiceModel.modelName)
        default:
            return modelsDirectory
        }
    }

    /// 下载模型
    func downloadModel(_ modelId: String, progress: @escaping (String) -> Void, completion: @escaping (Bool, String?) -> Void) {
        let downloadURL: String
        let modelName: String

        switch modelId {
        case "paraformer":
            downloadURL = ParaformerModel.downloadURL
            modelName = ParaformerModel.modelName
        case "sensevoice-small":
            downloadURL = SenseVoiceModel.downloadURL
            modelName = SenseVoiceModel.modelName
        default:
            completion(false, "未知模型类型")
            return
        }

        guard let url = URL(string: downloadURL) else {
            completion(false, "无效的下载地址")
            return
        }

        progress("正在下载 \(modelName)...")

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "下载失败: \(error.localizedDescription)")
                }
                return
            }

            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion(false, "下载失败: 无法获取临时文件")
                }
                return
            }

            progress("正在解压模型...")

            // 解压到模型目录
            let destDir = self.modelsDirectory
            let result = self.extractTarBz2(from: tempURL, to: destDir)

            DispatchQueue.main.async {
                if result {
                    completion(true, nil)
                } else {
                    completion(false, "解压失败")
                }
            }
        }

        task.resume()
    }

    /// 解压 tar.bz2 文件
    private func extractTarBz2(from sourceURL: URL, to destDir: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xjf", sourceURL.path, "-C", destDir.path]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("解压失败: \(error)")
            return false
        }
    }
}
