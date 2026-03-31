import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.groupedByEvent(search: search), id: \.0) { event, clips in
                    Section(event) {
                        ForEach(clips) { clip in
                            NavigationLink { VideoPlayerView(localIdentifier: clip.id, clip: clip) } label: { ClipRow(clip: clip) }
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .searchable(text: $search, prompt: "Search event, artist, song")
        }
    }
}
