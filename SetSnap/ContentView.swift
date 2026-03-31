import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        Group { if appState.hasReadAccess { MainTabView() } else { PermissionView() } }
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            LibraryView().tabItem { Label("Library", systemImage: "photo.stack") }
            ArtistsView().tabItem { Label("Artists", systemImage: "music.mic") }
            EventsView().tabItem { Label("Events", systemImage: "calendar.badge.clock") }
            SnippetsView().tabItem { Label("Snippets", systemImage: "scissors") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .overlay(alignment: .bottom) {
            if !appState.statusMessage.isEmpty {
                Text(appState.statusMessage).font(.footnote).padding(10).background(.thinMaterial).clipShape(Capsule()).padding(.bottom, 8)
            }
        }
    }
}
