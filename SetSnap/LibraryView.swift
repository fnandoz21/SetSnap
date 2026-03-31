import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var search = ""

    var body: some View {
        NavigationStack {
            Group {
                if appState.assets.isEmpty { ContentUnavailableView("No indexed videos yet", systemImage: "film") }
                else {
                    List {
                        statsSection
                        Section("All Concert Clips") {
                            ForEach(appState.allConcertClips(search: search)) { clip in
                                NavigationLink { VideoPlayerView(localIdentifier: clip.id, clip: clip) } label: { ClipRow(clip: clip) }
                            }
                        }
                        Section("Unidentified") {
                            ForEach(appState.unidentifiedClips()) { clip in
                                NavigationLink { VideoPlayerView(localIdentifier: clip.id, clip: clip) } label: { ClipRow(clip: clip) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $search, prompt: "Artist, song, event")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if appState.isScanning {
                        Button("Cancel") { Task { await appState.cancelScan() } }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appState.isScanning ? "Scanning..." : "Scan") { Task { await appState.startScan() } }.disabled(appState.isScanning)
                }
            }
        }
    }

    private var statsSection: some View {
        Section("Progress") {
            LabeledContent("Total videos", value: "\(appState.progress.totalVideos)")
            LabeledContent("Scanned", value: "\(appState.progress.scannedVideos)")
            LabeledContent("Likely concert", value: "\(appState.progress.likelyConcertVideos)")
            LabeledContent("Recognized", value: "\(appState.progress.recognizedVideos)")
            LabeledContent("Snippets generated", value: "\(appState.progress.snippetsGenerated)")
            LabeledContent("Snippets exported", value: "\(appState.progress.snippetsExported)")
            if appState.needsFullAccessMessaging {
                Text("Limited Photos access is active. Full access is recommended for complete scanning.").font(.footnote).foregroundStyle(.orange)
            }
        }
    }
}

struct ClipRow: View {
    let clip: ClipAsset

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(localIdentifier: clip.id).frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 5) {
                Text(clip.songTitle ?? "Unknown song").font(.headline)
                Text(clip.artistName ?? clip.eventTitle ?? "Unidentified").font(.subheadline).foregroundStyle(.secondary)
                Text("\(clip.duration, specifier: "%.0f")s • score \(clip.concertScore, format: .percent.precision(.fractionLength(0)))").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 2)
    }
}
