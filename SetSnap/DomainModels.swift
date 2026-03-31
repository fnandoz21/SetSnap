import Foundation
import CoreLocation

enum AnalysisStatus: String, Codable, CaseIterable {
    case pending, analyzing, completed, failed
}

enum RecognitionStatus: String, Codable, CaseIterable {
    case pending, matched, noMatch, unavailable, failed
}

enum SnippetStatus: String, Codable, CaseIterable {
    case pending, generated, failed
}

struct ClipAsset: Identifiable, Hashable {
    let id: String
    var creationDate: Date?
    var duration: Double
    var width: Int
    var height: Int
    var isFavorite: Bool
    var latitude: Double?
    var longitude: Double?
    var analysisStatus: AnalysisStatus
    var recognitionStatus: RecognitionStatus
    var snippetStatus: SnippetStatus
    var concertScore: Double
    var isLikelyConcert: Bool
    var artistName: String?
    var songTitle: String?
    var recognitionConfidence: Double?
    var eventID: String?
    var eventTitle: String?
    var lastError: String?
    var analyzedAt: Date?
}

struct ClipSnippet: Identifiable, Hashable {
    let id: String
    let assetID: String
    let startTime: Double
    let endTime: Double
    let type: SnippetType
    let score: Double
    var exportedAt: Date?
}

enum SnippetType: String, Codable, CaseIterable {
    case short, medium, hook
}

struct AnalysisMetrics: Hashable {
    let duration: Double
    let averageBrightness: Double
    let brightnessVariance: Double
    let audioRMS: Double
    let speechLikeRatio: Double
    let peakEnergyMoment: Double?
}

struct RecognitionResult: Hashable {
    let artist: String
    let song: String
    let confidence: Double
}

struct EventGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let dateStart: Date
    let dateEnd: Date
    let artistHint: String?
    let assetIDs: [String]
}

struct ProgressStats: Hashable {
    var totalVideos: Int = 0
    var scannedVideos: Int = 0
    var likelyConcertVideos: Int = 0
    var recognizedVideos: Int = 0
    var snippetsGenerated: Int = 0
    var snippetsExported: Int = 0
}

struct AppSettings: Hashable {
    var processOnlyOnWiFi: Bool = true
    var processOnlyWhileCharging: Bool = false
    var minimumVideoDuration: Double = 12
    var favoritesOnly: Bool = false
    var maxAssetsPerBatch: Int = 20
    var confidenceThreshold: Double = 0.55
    /// When true, only videos whose asset creation date falls within the optional bounds are fetched and processed.
    var videoDateFilterEnabled: Bool = false
    /// Inclusive lower bound (start of that calendar day). Nil means no lower bound.
    var videoDateRangeStart: Date? = nil
    /// Inclusive upper bound (end of that calendar day). Nil means no upper bound.
    var videoDateRangeEnd: Date? = nil
    static let `default` = AppSettings()
}
