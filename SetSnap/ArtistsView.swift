import SwiftUI

struct ArtistsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.groupedByArtist(search: search), id: \.0) { name, clips in
                    Section(name) {
                        ForEach(clips) { clip in
                            NavigationLink { VideoPlayerView(localIdentifier: clip.id, clip: clip) } label: { ClipRow(clip: clip) }
                        }
                    }
                }
            }
            .navigationTitle("Artists")
            .searchable(text: $search, prompt: "Search artist or song")
        }
    }
}
