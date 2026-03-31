import Foundation

protocol ConcertScoringServiceProtocol {
    func score(metrics: AnalysisMetrics, settings: AppSettings) -> Double
    func isLikelyConcert(metrics: AnalysisMetrics, settings: AppSettings) -> Bool
}

struct ConcertScoringService: ConcertScoringServiceProtocol {
    func score(metrics: AnalysisMetrics, settings: AppSettings) -> Double {
        let durationScore = min(1.0, max(0.0, (metrics.duration - settings.minimumVideoDuration) / 60.0))
        let brightnessScore = 1.0 - min(1.0, max(0.0, metrics.averageBrightness))
        let lightingVarianceScore = min(1.0, metrics.brightnessVariance * 8.0)
        let musicEnergyScore = min(1.0, metrics.audioRMS * 5.5)
        let speechPenalty = min(1.0, max(0.0, metrics.speechLikeRatio))
        let weighted = (durationScore * 0.20 + brightnessScore * 0.20 + lightingVarianceScore * 0.20 + musicEnergyScore * 0.30 + (1.0 - speechPenalty) * 0.10)
        return min(1.0, max(0.0, weighted))
    }

    func isLikelyConcert(metrics: AnalysisMetrics, settings: AppSettings) -> Bool {
        score(metrics: metrics, settings: settings) >= settings.confidenceThreshold
    }
}
