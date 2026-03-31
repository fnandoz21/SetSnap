import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var search = ""

    var body: some View {
        NavigationStack {
            ConcertRoot {
                Group {
                    if appState.assets.isEmpty {
                        VStack(spacing: AppTheme.spacingM) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 42))
                                .foregroundStyle(AppTheme.secondaryAccent)
                            Text("No indexed videos yet")
                                .font(.title3.weight(.semibold))
                            Text("Tap Scan to analyze your library.")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                progressCard
                            }
                            .listRowBackground(Color.clear)

                            Section("All Concert Clips") {
                                ForEach(appState.allConcertClips(search: search)) { clip in
                                    NavigationLink { VideoPlayerView(localIdentifier: clip.id, clip: clip) } label: { ClipRow(clip: clip) }
                                        .listRowBackground(AppTheme.surface)
                                }
                            }

                            Section("Unidentified") {
                                ForEach(appState.unidentifiedClips()) { clip in
                                    NavigationLink { VideoPlayerView(localIdentifier: clip.id, clip: clip) } label: { ClipRow(clip: clip) }
                                        .listRowBackground(AppTheme.surface)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                    Button(appState.isScanning ? "Scanning..." : "Scan") { Task { await appState.startScan() } }
                        .disabled(appState.isScanning)
                }
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                Text("Scan Progress").font(.headline)
                Spacer()
                AccentBadge(text: appState.isScanning ? "LIVE" : "READY", tone: appState.isScanning ? AppTheme.primaryAccent : AppTheme.secondaryAccent)
            }

            statRow("Total videos", appState.progress.totalVideos)
            statRow("Scanned", appState.progress.scannedVideos)
            statRow("Likely concert", appState.progress.likelyConcertVideos)
            statRow("Recognized", appState.progress.recognizedVideos)
            statRow("Snippets generated", appState.progress.snippetsGenerated)
            statRow("Snippets exported", appState.progress.snippetsExported)

            if appState.needsFullAccessMessaging {
                Text("Limited Photos access is active. Full access is recommended.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .concertCard()
    }

    private func statRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label).foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("\(value)").fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct ClipRow: View {
    let clip: ClipAsset

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            ThumbnailView(localIdentifier: clip.id)
                .frame(width: 66, height: 66)
            VStack(alignment: .leading, spacing: 6) {
                Text(clip.songTitle ?? "Unknown song")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(clip.artistName ?? clip.eventTitle ?? "Unidentified")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 6) {
                    AccentBadge(text: String(format: "%.0fs", clip.duration), tone: AppTheme.secondaryAccent)
                    AccentBadge(text: clip.concertScore, tone: AppTheme.primaryAccent)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private extension AccentBadge {
    init(text value: Double, tone: Color) {
        self.init(text: value.formatted(.percent.precision(.fractionLength(0))), tone: tone)
    }
}
