import Foundation

protocol SnippetGenerationServiceProtocol {
    func generateSnippets(for asset: ClipAsset, metrics: AnalysisMetrics, energyTimeline: [Double]) -> [ClipSnippet]
}

struct SnippetGenerationService: SnippetGenerationServiceProtocol {
    func generateSnippets(for asset: ClipAsset, metrics: AnalysisMetrics, energyTimeline: [Double]) -> [ClipSnippet] {
        let duration = asset.duration
        guard duration > 8 else { return [] }
        let shortLength = min(15.0, max(10.0, duration * 0.2))
        let mediumLength = min(30.0, max(20.0, duration * 0.35))
        let peakSecond: Double = energyTimeline.enumerated().max(by: { $0.element < $1.element }).map { Double($0.offset) } ?? metrics.peakEnergyMoment ?? max(0, duration * 0.4)

        let shortStart = clamp(peakSecond - shortLength / 2, min: 0, max: max(0, duration - shortLength))
        let mediumStart = clamp(peakSecond - mediumLength / 2, min: 0, max: max(0, duration - mediumLength))
        let hookStart = clamp(peakSecond - 6, min: 0, max: max(0, duration - 12))

        let baseEnergy = energyTimeline.isEmpty ? metrics.audioRMS : (energyTimeline.reduce(0, +) / Double(energyTimeline.count))
        let clarity = max(0, 1.0 - metrics.speechLikeRatio)
        let visibility = max(0, 1.0 - metrics.averageBrightness)

        let shortScore = min(1.0, baseEnergy * 0.55 + clarity * 0.25 + visibility * 0.20)
        let mediumScore = min(1.0, baseEnergy * 0.50 + clarity * 0.30 + visibility * 0.20)
        let hookScore = min(1.0, baseEnergy * 0.60 + clarity * 0.30 + visibility * 0.10)

        return [
            ClipSnippet(id: "\(asset.id)_short", assetID: asset.id, startTime: shortStart, endTime: shortStart + shortLength, type: .short, score: shortScore, exportedAt: nil),
            ClipSnippet(id: "\(asset.id)_medium", assetID: asset.id, startTime: mediumStart, endTime: mediumStart + mediumLength, type: .medium, score: mediumScore, exportedAt: nil),
            ClipSnippet(id: "\(asset.id)_hook", assetID: asset.id, startTime: hookStart, endTime: hookStart + min(12.0, duration), type: .hook, score: hookScore, exportedAt: nil)
        ]
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
