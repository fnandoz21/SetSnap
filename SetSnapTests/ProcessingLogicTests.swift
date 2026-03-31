import XCTest
@testable import SetSnap

final class ProcessingLogicTests: XCTestCase {
    func testConcertScoreIncreasesWithMusicLikeMetrics() {
        let service = ConcertScoringService()
        let settings = AppSettings.default
        let weakMetrics = AnalysisMetrics(duration: 14, averageBrightness: 0.8, brightnessVariance: 0.02, audioRMS: 0.03, speechLikeRatio: 0.9, peakEnergyMoment: nil)
        let strongMetrics = AnalysisMetrics(duration: 56, averageBrightness: 0.28, brightnessVariance: 0.2, audioRMS: 0.22, speechLikeRatio: 0.2, peakEnergyMoment: 20)
        XCTAssertLessThan(service.score(metrics: weakMetrics, settings: settings), service.score(metrics: strongMetrics, settings: settings))
        XCTAssertTrue(service.isLikelyConcert(metrics: strongMetrics, settings: settings))
    }

    func testSnippetGenerationRespectsDurationBounds() {
        let generator = SnippetGenerationService()
        let clip = ClipAsset(id: "clip1", creationDate: Date(), duration: 45, width: 1920, height: 1080, isFavorite: false, latitude: nil, longitude: nil, analysisStatus: .completed, recognitionStatus: .matched, snippetStatus: .pending, concertScore: 0.8, isLikelyConcert: true, artistName: "A", songTitle: "B", recognitionConfidence: 0.7, eventID: nil, eventTitle: nil, lastError: nil, analyzedAt: Date())
        let metrics = AnalysisMetrics(duration: 45, averageBrightness: 0.3, brightnessVariance: 0.2, audioRMS: 0.18, speechLikeRatio: 0.4, peakEnergyMoment: 24)
        let snippets = generator.generateSnippets(for: clip, metrics: metrics, energyTimeline: [0.02, 0.08, 0.2, 0.19, 0.1])
        XCTAssertEqual(snippets.count, 3)
        XCTAssertTrue(snippets.allSatisfy { $0.startTime >= 0 && $0.endTime <= clip.duration })
    }

    func testEventGroupingClustersSameNight() {
        let grouper = EventGroupingService()
        let baseDate = Date()
        let clip1 = ClipAsset(id: "1", creationDate: baseDate, duration: 20, width: 1, height: 1, isFavorite: false, latitude: 40.7, longitude: -74.0, analysisStatus: .completed, recognitionStatus: .matched, snippetStatus: .generated, concertScore: 0.7, isLikelyConcert: true, artistName: "Band", songTitle: "Song", recognitionConfidence: 0.8, eventID: nil, eventTitle: nil, lastError: nil, analyzedAt: nil)
        let clip2 = ClipAsset(id: "2", creationDate: baseDate.addingTimeInterval(1800), duration: 30, width: 1, height: 1, isFavorite: false, latitude: 40.7005, longitude: -74.0005, analysisStatus: .completed, recognitionStatus: .matched, snippetStatus: .generated, concertScore: 0.7, isLikelyConcert: true, artistName: "Band", songTitle: "Song2", recognitionConfidence: 0.8, eventID: nil, eventTitle: nil, lastError: nil, analyzedAt: nil)
        let clip3 = ClipAsset(id: "3", creationDate: baseDate.addingTimeInterval(24 * 3600), duration: 25, width: 1, height: 1, isFavorite: false, latitude: 34.0, longitude: -118.2, analysisStatus: .completed, recognitionStatus: .matched, snippetStatus: .generated, concertScore: 0.7, isLikelyConcert: true, artistName: "Other", songTitle: "x", recognitionConfidence: 0.8, eventID: nil, eventTitle: nil, lastError: nil, analyzedAt: nil)
        let groups = grouper.inferEventGroups(from: [clip1, clip2, clip3])
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups.first?.assetIDs.count, 2)
    }
}
