import Foundation
import AVFoundation
import CoreImage

protocol MediaAnalysisServiceProtocol {
    func analyze(asset: AVAsset) async throws -> AnalysisMetrics
    func energyTimeline(asset: AVAsset, bucketSize: Double) async throws -> [Double]
}

struct MediaAnalysisService: MediaAnalysisServiceProtocol {
    func analyze(asset: AVAsset) async throws -> AnalysisMetrics {
        async let brightnessTask = sampleBrightness(asset: asset)
        async let audioTask = sampleAudioEnergy(asset: asset)
        let brightness = try await brightnessTask
        let audio = try await audioTask
        return AnalysisMetrics(duration: max(0, CMTimeGetSeconds(asset.duration)), averageBrightness: brightness.average, brightnessVariance: brightness.variance, audioRMS: audio.rms, speechLikeRatio: audio.speechLikeRatio, peakEnergyMoment: audio.peakMoment)
    }

    func energyTimeline(asset: AVAsset, bucketSize: Double = 1.0) async throws -> [Double] {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return [] }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ])
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        reader.startReading()

        var timeline: [Double] = []
        var runningEnergy = 0.0
        var runningSamples = 0
        let bucketDuration = max(0.5, bucketSize)
        var currentBucketStart = 0.0

        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer(), let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { break }
            let pts = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            let length = CMBlockBufferGetDataLength(blockBuffer)
            var data = Data(count: length)
            data.withUnsafeMutableBytes { rawBuffer in
                guard let baseAddress = rawBuffer.baseAddress else { return }
                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: baseAddress)
            }
            data.withUnsafeBytes { ptr in
                for s in ptr.bindMemory(to: Int16.self) {
                    let normalized = Double(s) / Double(Int16.max)
                    runningEnergy += normalized * normalized
                    runningSamples += 1
                }
            }
            if pts - currentBucketStart >= bucketDuration && runningSamples > 0 {
                timeline.append(sqrt(runningEnergy / Double(runningSamples)))
                currentBucketStart = pts
                runningEnergy = 0
                runningSamples = 0
            }
        }
        if runningSamples > 0 { timeline.append(sqrt(runningEnergy / Double(runningSamples))) }
        return timeline
    }

    private func sampleBrightness(asset: AVAsset) async throws -> (average: Double, variance: Double) {
        guard (try await asset.loadTracks(withMediaType: .video).first) != nil else { return (0.5, 0.0) }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)

        let duration = CMTimeGetSeconds(asset.duration)
        let times = (0..<8).map { NSValue(time: CMTime(seconds: duration * Double($0 + 1) / 9.0, preferredTimescale: 600)) }

        var values: [Double] = []
        for t in times {
            if let cg = try? imageGenerator.copyCGImage(at: t.timeValue, actualTime: nil) { values.append(averageLuminance(cgImage: cg)) }
        }
        guard !values.isEmpty else { return (0.5, 0.0) }
        let avg = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count)
        return (avg, variance)
    }

    private func averageLuminance(cgImage: CGImage) -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        guard let out = filter.outputImage else { return 0.5 }
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(out, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func sampleAudioEnergy(asset: AVAsset) async throws -> (rms: Double, speechLikeRatio: Double, peakMoment: Double?) {
        let timeline = try await energyTimeline(asset: asset, bucketSize: 1.0)
        guard !timeline.isEmpty else { return (0.0, 0.8, nil) }
        let rms = timeline.reduce(0, +) / Double(timeline.count)
        let std = sqrt(timeline.map { pow($0 - rms, 2) }.reduce(0, +) / Double(timeline.count))
        let speechLikeRatio = min(1.0, max(0.0, 0.7 - (std * 1.8) + (0.15 - rms)))
        let peakMoment = timeline.enumerated().max(by: { $0.element < $1.element }).map { Double($0.offset) }
        return (rms, speechLikeRatio, peakMoment)
    }
}
