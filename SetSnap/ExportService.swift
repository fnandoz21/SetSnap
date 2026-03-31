import Foundation
import AVFoundation
import Photos

protocol ExportServiceProtocol {
    func exportSnippet(asset: AVAsset, snippet: ClipSnippet) async throws -> URL
    func saveToPhotos(_ url: URL) async throws
}

struct ExportService: ExportServiceProtocol {
    func exportSnippet(asset: AVAsset, snippet: ClipSnippet) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("SetSnap_\(snippet.id)_\(UUID().uuidString).mov")
        if FileManager.default.fileExists(atPath: outputURL.path) { try FileManager.default.removeItem(at: outputURL) }

        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "ExportService", code: 12, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."])
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.timeRange = CMTimeRange(start: CMTime(seconds: snippet.startTime, preferredTimescale: 600), end: CMTime(seconds: snippet.endTime, preferredTimescale: 600))
        exporter.shouldOptimizeForNetworkUse = true

        try await withCheckedThrowingContinuation { continuation in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed: continuation.resume(returning: ())
                case .failed, .cancelled: continuation.resume(throwing: exporter.error ?? NSError(domain: "ExportService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Export cancelled or failed."]))
                default: break
                }
            }
        }
        return outputURL
    }

    func saveToPhotos(_ url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if let error { continuation.resume(throwing: error); return }
                if success { continuation.resume(returning: ()) }
                else { continuation.resume(throwing: NSError(domain: "ExportService", code: 14, userInfo: [NSLocalizedDescriptionKey: "Unknown save to Photos failure."])) }
            }
        }
    }
}
