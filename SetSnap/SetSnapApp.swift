import SwiftUI
import UIKit

@main
struct SetSnapApp: App {
    @StateObject private var appState = AppState.bootstrap()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.handleAppLaunch()
                }
        }
    }

    private func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(AppTheme.background)
        nav.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.textPrimary)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.textPrimary)]
        nav.shadowColor = UIColor(AppTheme.divider)

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.primaryAccent)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(AppTheme.surface)
        tab.shadowColor = UIColor(AppTheme.divider)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
