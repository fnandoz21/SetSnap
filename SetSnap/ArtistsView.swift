import SwiftUI

struct ArtistsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var search = ""

    var body: some View {
        NavigationStack {
            ConcertRoot {
                List {
                    ForEach(appState.groupedByArtist(search: search), id: \.0) { name, clips in
                        Section {
                            ForEach(clips) { clip in
                                NavigationLink {
                                    VideoPlayerView(localIdentifier: clip.id, clip: clip)
                                } label: {
                                    ClipRow(clip: clip)
                                }
                                .listRowBackground(AppTheme.surface)
                            }
                        } header: {
                            HStack {
                                Text(name)
                                Spacer()
                                AccentBadge(text: "\(clips.count)", tone: AppTheme.secondaryAccent)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Artists")
            .searchable(text: $search, prompt: "Search artist or song")
        }
    }
}
