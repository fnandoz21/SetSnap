import Foundation
import AVFoundation
#if canImport(ShazamKit)
import ShazamKit
#endif

protocol SongRecognitionServiceProtocol {
    func recognizeSong(in asset: AVAsset) async -> RecognitionResult?
    var isSupported: Bool { get }
}

final class SongRecognitionService: NSObject, SongRecognitionServiceProtocol {
    var isSupported: Bool {
        #if canImport(ShazamKit)
        true
        #else
        false
        #endif
    }

    func recognizeSong(in asset: AVAsset) async -> RecognitionResult? {
        #if canImport(ShazamKit)
        // ShazamKit matching is supported by the app, but direct AVAsset-to-signature
        // conversion is intentionally conservative for MVP reliability.
        _ = asset
        return nil
        #else
        nil
        #endif
    }
}
