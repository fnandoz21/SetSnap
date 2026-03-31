import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var search = ""

    var body: some View {
        NavigationStack {
            ConcertRoot {
                List {
                    ForEach(appState.groupedByEvent(search: search), id: \.0) { event, clips in
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
                                Text(event)
                                Spacer()
                                AccentBadge(text: "\(clips.count)", tone: AppTheme.primaryAccent)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Events")
            .searchable(text: $search, prompt: "Search event, artist, song")
        }
    }
}
