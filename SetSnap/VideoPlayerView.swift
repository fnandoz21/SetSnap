import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @EnvironmentObject private var appState: AppState
    let localIdentifier: String
    let clip: ClipAsset
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 16) {
            if let player {
                VideoPlayer(player: player).frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.2)).frame(height: 280).overlay { ProgressView() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(clip.songTitle ?? "Unknown song").font(.title3).bold()
                Text(clip.artistName ?? "Unknown artist").foregroundStyle(.secondary)
                Text("Concert score: \(clip.concertScore, format: .percent.precision(.fractionLength(0)))").font(.footnote).foregroundStyle(.secondary)
            }

            List {
                Section("Suggested snippets") {
                    ForEach(appState.snippetsForAsset(localIdentifier)) { snippet in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(snippet.type.rawValue.capitalized)
                                Text("\(snippet.startTime, specifier: "%.1f")s - \(snippet.endTime, specifier: "%.1f")s").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Export") { Task { await appState.export(snippet: snippet) } }.buttonStyle(.bordered)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .padding()
        .navigationTitle("Clip Detail")
        .task {
            guard let phAsset = appState.phAsset(for: localIdentifier) else { return }
            if let item = await PhotosService().requestPlayerItem(for: phAsset) { player = AVPlayer(playerItem: item) }
        }
    }
}
