import Foundation
import SwiftUI
import Photos
import Network

@MainActor
final class AppState: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isScanning = false
    @Published var statusMessage = ""
    @Published var progress = ProgressStats()
    @Published var assets: [ClipAsset] = []
    @Published var snippets: [ClipSnippet] = []
    @Published var settings: AppSettings = .default

    private let photos: PhotosServiceProtocol
    private let store: SQLiteStore
    private let pipeline: ProcessingPipeline
    private let exportService: ExportServiceProtocol
    private let monitor = NWPathMonitor()
    private var networkSatisfied = true
    private var statusDismissTask: Task<Void, Never>?

    static func bootstrap() -> AppState {
        let photos = PhotosService()
        let store = try! SQLiteStore()
        return AppState(
            photos: photos,
            store: store,
            pipeline: ProcessingPipeline(photos: photos, store: store, analysis: MediaAnalysisService(), scorer: ConcertScoringService(), recognizer: SongRecognitionService(), grouping: EventGroupingService(), snippetGenerator: SnippetGenerationService()),
            exportService: ExportService()
        )
    }

    init(photos: PhotosServiceProtocol, store: SQLiteStore, pipeline: ProcessingPipeline, exportService: ExportServiceProtocol) {
        self.photos = photos
        self.store = store
        self.pipeline = pipeline
        self.exportService = exportService
        monitor.pathUpdateHandler = { [weak self] p in
            Task { @MainActor in self?.networkSatisfied = (p.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "SetSnap.NetworkMonitor"))
    }

    func handleAppLaunch() async {
        authorizationStatus = photos.authorizationStatus()
        settings = await store.loadSettings()
        await reloadFromStore()
    }

    func requestPhotosAccess() async {
        authorizationStatus = await photos.requestAuthorization()
        await reloadFromStore()
    }

    var hasReadAccess: Bool { authorizationStatus == .authorized || authorizationStatus == .limited }
    var needsFullAccessMessaging: Bool { authorizationStatus == .limited }

    func reloadFromStore() async {
        assets = await store.loadAssets()
        snippets = await store.loadSnippets()
        progress = await pipeline.currentStats()
    }

    func updateSettings(_ updated: AppSettings) async {
        settings = updated
        await store.saveSettings(updated)
    }

    func startScan() async {
        guard hasReadAccess else {
            scheduleTransientStatus("Photos permission required.", seconds: 4)
            return
        }
        if settings.processOnlyOnWiFi && !networkSatisfied {
            scheduleTransientStatus("Waiting for Wi-Fi (or disable Wi-Fi-only).", seconds: 4)
            return
        }

        statusDismissTask?.cancel()
        isScanning = true
        statusMessage = "Scanning and analyzing videos..."
        await pipeline.runScan(settings: settings) { [weak self] stats in
            await MainActor.run { [weak self] in
                self?.progress = stats
            }
        }
        await reloadFromStore()
        isScanning = false
        scheduleTransientStatus("Scan complete.", seconds: 3)
    }

    func cancelScan() async {
        await pipeline.cancel()
        isScanning = false
        scheduleTransientStatus("Scan cancelled.", seconds: 2)
    }

    /// Clears the bottom status banner after a delay (replaces prior scheduled clear).
    private func scheduleTransientStatus(_ message: String, seconds: TimeInterval) {
        statusDismissTask?.cancel()
        statusMessage = message
        statusDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            if self.statusMessage == message {
                self.statusMessage = ""
            }
        }
    }

    func allConcertClips(search: String = "") -> [ClipAsset] {
        let base = assets.filter { $0.isLikelyConcert }
        guard !search.isEmpty else { return base }
        return base.filter {
            $0.artistName?.localizedCaseInsensitiveContains(search) == true ||
            $0.songTitle?.localizedCaseInsensitiveContains(search) == true ||
            $0.eventTitle?.localizedCaseInsensitiveContains(search) == true
        }
    }

    func unidentifiedClips() -> [ClipAsset] { assets.filter { $0.isLikelyConcert && $0.artistName == nil && $0.songTitle == nil } }

    func groupedByArtist(search: String = "") -> [(String, [ClipAsset])] {
        let groups = Dictionary(grouping: allConcertClips(search: search)) { $0.artistName?.isEmpty == false ? $0.artistName! : "Unidentified" }
        return groups.map { ($0.key, $0.value) }.sorted(by: { $0.0 < $1.0 })
    }

    func groupedByEvent(search: String = "") -> [(String, [ClipAsset])] {
        let groups = Dictionary(grouping: allConcertClips(search: search)) { $0.eventTitle ?? "Unidentified Night" }
        return groups.map { ($0.key, $0.value) }.sorted(by: { $0.0 < $1.0 })
    }

    func snippetsForAsset(_ assetID: String) -> [ClipSnippet] { snippets.filter { $0.assetID == assetID }.sorted { $0.score > $1.score } }

    func phAsset(for localID: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil).firstObject
    }

    func export(snippet: ClipSnippet) async {
        guard let phAsset = phAsset(for: snippet.assetID) else {
            scheduleTransientStatus("Could not locate original asset.", seconds: 4)
            return
        }
        do {
            let avAsset = try await photos.requestAVAsset(for: phAsset)
            let url = try await exportService.exportSnippet(asset: avAsset, snippet: snippet)
            try await exportService.saveToPhotos(url)
            await store.markSnippetExported(id: snippet.id, at: Date())
            await reloadFromStore()
            scheduleTransientStatus("Snippet exported to Photos.", seconds: 3)
        } catch {
            scheduleTransientStatus("Export failed: \(error.localizedDescription)", seconds: 5)
        }
    }
}
