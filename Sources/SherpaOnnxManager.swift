import Foundation

/// FunASR Nano 模型管理器
class SherpaOnnxManager: NSObject {
    static let shared = SherpaOnnxManager()

    /// 下载进度回调
    private var progressCallback: ((String) -> Void)?
    /// 下载完成回调
    private var completionCallback: ((Bool, String?) -> Void)?
    /// 当前下载的模型名称
    private var currentModelName: String?
    /// 当前下载任务
    private var currentDownloadTask: URLSessionDownloadTask?

    /// 模型存储根目录
    private let modelsDirectory: URL = {
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Typeless/models")
        try? FileManager.default.createDirectory(at: appSupportPath, withIntermediateDirectories: true)
        return appSupportPath
    }()

    /// 模型配置
    static let modelId = "sense-voice-funasr-nano"
    static let folderName = "sherpa-onnx-sense-voice-funasr-nano-int8-2025-12-17"
    static let downloadURL = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-sense-voice-funasr-nano-int8-2025-12-17.tar.bz2"
    static let displayName = "SenseVoice FunASR Nano"

    /// 获取模型路径
    func getModelPath() -> (modelPath: String, tokensPath: String)? {
        let modelDir = modelsDirectory.appendingPathComponent(Self.folderName)
        let modelPath = modelDir.appendingPathComponent("model.int8.onnx")
        let tokensPath = modelDir.appendingPathComponent("tokens.txt")

        guard FileManager.default.fileExists(atPath: modelPath.path),
              FileManager.default.fileExists(atPath: tokensPath.path) else {
            return nil
        }

        return (modelPath.path, tokensPath.path)
    }

    /// 检查模型是否已下载
    func isModelDownloaded() -> Bool {
        return getModelPath() != nil
    }

    /// 下载模型
    func downloadModel(progress: @escaping (String) -> Void, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: Self.downloadURL) else {
            completion(false, "无效的下载地址")
            return
        }

        self.progressCallback = progress
        self.completionCallback = completion
        self.currentModelName = Self.displayName

        progress("正在下载 \(Self.displayName)...")

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)

        let task = session.downloadTask(with: url)
        self.currentDownloadTask = task
        task.resume()
    }

    /// 格式化文件大小
    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        if mb >= 1 {
            return String(format: "%.1fMB", mb)
        } else {
            return String(format: "%.0fKB", kb)
        }
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

// MARK: - URLSessionDownloadDelegate
extension SherpaOnnxManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let modelName = currentModelName ?? "模型"

        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            let percentage = Int(progress * 100)
            let downloaded = formatBytes(totalBytesWritten)
            let total = formatBytes(totalBytesExpectedToWrite)
            progressCallback?("正在下载 \(modelName)... \(percentage)% (\(downloaded) / \(total))")
        } else {
            let downloaded = formatBytes(totalBytesWritten)
            progressCallback?("正在下载 \(modelName)... \(downloaded)")
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        progressCallback?("正在解压模型...")

        let result = extractTarBz2(from: location, to: modelsDirectory)

        if result {
            completionCallback?(true, nil)
        } else {
            completionCallback?(false, "解压失败")
        }

        currentModelName = nil
        currentDownloadTask = nil
        progressCallback = nil
        completionCallback = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionCallback?(false, "下载失败: \(error.localizedDescription)")

            currentModelName = nil
            currentDownloadTask = nil
            progressCallback = nil
            completionCallback = nil
        }
    }
}
