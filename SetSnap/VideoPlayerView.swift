import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @EnvironmentObject private var appState: AppState
    let localIdentifier: String
    let clip: ClipAsset
    @State private var player: AVPlayer?

    var body: some View {
        ConcertRoot {
            VStack(spacing: AppTheme.spacingM) {
                if let player {
                    VideoPlayer(player: player)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardRadius).stroke(AppTheme.divider, lineWidth: 1))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .fill(AppTheme.surface)
                        .frame(height: 300)
                        .overlay { ProgressView().tint(AppTheme.secondaryAccent) }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(clip.songTitle ?? "Unknown song")
                        .font(.title3.bold())
                    Text(clip.artistName ?? "Unknown artist")
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 8) {
                        AccentBadge(text: clip.concertScore.formatted(.percent.precision(.fractionLength(0))), tone: AppTheme.primaryAccent)
                        AccentBadge(text: String(format: "%.0fs", clip.duration), tone: AppTheme.secondaryAccent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .concertCard()

                List {
                    Section("Suggested snippets") {
                        ForEach(appState.snippetsForAsset(localIdentifier)) { snippet in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(snippet.type.rawValue.capitalized)
                                    Text("\(snippet.startTime, specifier: "%.1f")s - \(snippet.endTime, specifier: "%.1f")s")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Button("Export") {
                                    Task { await appState.export(snippet: snippet) }
                                }
                                .buttonStyle(PrimaryConcertButtonStyle())
                            }
                            .listRowBackground(AppTheme.surface)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .padding(AppTheme.spacingM)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Clip Detail")
        .task {
            guard let phAsset = appState.phAsset(for: localIdentifier) else { return }
            if let item = await PhotosService().requestPlayerItem(for: phAsset) {
                player = AVPlayer(playerItem: item)
            }
        }
    }
}
