import Foundation
import Photos

actor ProcessingPipeline {
    private let photos: PhotosServiceProtocol
    private let store: SQLiteStore
    private let analysis: MediaAnalysisServiceProtocol
    private let scorer: ConcertScoringServiceProtocol
    private let recognizer: SongRecognitionServiceProtocol
    private let grouping: EventGroupingServiceProtocol
    private let snippetGenerator: SnippetGenerationServiceProtocol
    private var cancelled = false

    init(photos: PhotosServiceProtocol, store: SQLiteStore, analysis: MediaAnalysisServiceProtocol, scorer: ConcertScoringServiceProtocol, recognizer: SongRecognitionServiceProtocol, grouping: EventGroupingServiceProtocol, snippetGenerator: SnippetGenerationServiceProtocol) {
        self.photos = photos
        self.store = store
        self.analysis = analysis
        self.scorer = scorer
        self.recognizer = recognizer
        self.grouping = grouping
        self.snippetGenerator = snippetGenerator
    }

    func cancel() { cancelled = true }

    func runScan(settings: AppSettings, progress: @escaping @Sendable (ProgressStats) async -> Void) async {
        cancelled = false
        let phAssets = photos.fetchVideoAssets(
            favoritesOnly: settings.favoritesOnly,
            minDuration: settings.minimumVideoDuration,
            dateFilterEnabled: settings.videoDateFilterEnabled,
            dateRangeStart: settings.videoDateRangeStart,
            dateRangeEnd: settings.videoDateRangeEnd
        )

        var byID = Dictionary(uniqueKeysWithValues: (await store.loadAssets()).map { ($0.id, $0) })
        for phAsset in phAssets {
            if byID[phAsset.localIdentifier] == nil {
                byID[phAsset.localIdentifier] = ClipAsset(
                    id: phAsset.localIdentifier,
                    creationDate: phAsset.creationDate,
                    duration: phAsset.duration,
                    width: phAsset.pixelWidth,
                    height: phAsset.pixelHeight,
                    isFavorite: phAsset.isFavorite,
                    latitude: phAsset.location?.coordinate.latitude,
                    longitude: phAsset.location?.coordinate.longitude,
                    analysisStatus: .pending,
                    recognitionStatus: .pending,
                    snippetStatus: .pending,
                    concertScore: 0,
                    isLikelyConcert: false,
                    artistName: nil,
                    songTitle: nil,
                    recognitionConfidence: nil,
                    eventID: nil,
                    eventTitle: nil,
                    lastError: nil,
                    analyzedAt: nil
                )
            }
        }
        for asset in byID.values { await store.upsertAsset(asset) }

        let pending = (await store.loadAssets()).filter { $0.analysisStatus != .completed || $0.snippetStatus != .generated }
        let batch = Array(pending.prefix(settings.maxAssetsPerBatch))

        for clip in batch {
            if cancelled { return }
            var mutable = clip
            mutable.analysisStatus = .analyzing
            await store.upsertAsset(mutable)
            await progress(await currentStats())

            do {
                guard let phAsset = phAssets.first(where: { $0.localIdentifier == mutable.id }) else { continue }
                let avAsset = try await photos.requestAVAsset(for: phAsset)
                let metrics = try await analysis.analyze(asset: avAsset)
                mutable.concertScore = scorer.score(metrics: metrics, settings: settings)
                mutable.isLikelyConcert = scorer.isLikelyConcert(metrics: metrics, settings: settings)
                mutable.analysisStatus = .completed
                mutable.analyzedAt = Date()

                if mutable.isLikelyConcert {
                    if recognizer.isSupported, let result = await recognizer.recognizeSong(in: avAsset) {
                        mutable.recognitionStatus = .matched
                        mutable.artistName = result.artist
                        mutable.songTitle = result.song
                        mutable.recognitionConfidence = result.confidence
                    } else {
                        mutable.recognitionStatus = recognizer.isSupported ? .noMatch : .unavailable
                    }
                    let energy = (try? await analysis.energyTimeline(asset: avAsset, bucketSize: 1.0)) ?? []
                    let snippets = snippetGenerator.generateSnippets(for: mutable, metrics: metrics, energyTimeline: energy)
                    mutable.snippetStatus = snippets.isEmpty ? .failed : .generated
                    await store.replaceSnippets(for: mutable.id, snippets: snippets)
                }
                mutable.lastError = nil
            } catch {
                mutable.analysisStatus = .failed
                mutable.recognitionStatus = .failed
                mutable.snippetStatus = .failed
                mutable.lastError = error.localizedDescription
            }

            await store.upsertAsset(mutable)

            let refreshed = await store.loadAssets()
            for group in grouping.inferEventGroups(from: refreshed) {
                for assetID in group.assetIDs {
                    if var a = refreshed.first(where: { $0.id == assetID }) {
                        a.eventID = group.id
                        a.eventTitle = group.title
                        await store.upsertAsset(a)
                    }
                }
            }
            await progress(await currentStats())
        }
    }

    func currentStats() async -> ProgressStats {
        let assets = await store.loadAssets()
        let snippets = await store.loadSnippets()
        return ProgressStats(
            totalVideos: assets.count,
            scannedVideos: assets.filter { $0.analysisStatus == .completed }.count,
            likelyConcertVideos: assets.filter { $0.isLikelyConcert }.count,
            recognizedVideos: assets.filter { $0.recognitionStatus == .matched }.count,
            snippetsGenerated: snippets.count,
            snippetsExported: snippets.filter { $0.exportedAt != nil }.count
        )
    }
}
