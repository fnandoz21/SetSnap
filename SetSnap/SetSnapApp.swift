import SwiftUI

@main
struct SetSnapApp: App {
    @StateObject private var appState = AppState.bootstrap()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.handleAppLaunch()
                }
        }
    }
}
