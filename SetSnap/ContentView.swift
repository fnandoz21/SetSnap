import SwiftUI

struct AppTheme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let surfaceSecondary = Color(red: 0.11, green: 0.11, blue: 0.16)
    static let primaryAccent = Color(red: 0.82, green: 0.30, blue: 0.86)
    static let secondaryAccent = Color(red: 0.24, green: 0.74, blue: 0.89)
    static let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
    static let textSecondary = Color(red: 0.63, green: 0.65, blue: 0.71)
    static let divider = Color.white.opacity(0.08)
    static let success = Color(red: 0.35, green: 0.78, blue: 0.57)
    static let warning = Color(red: 0.91, green: 0.63, blue: 0.32)
    static let danger = Color(red: 0.88, green: 0.35, blue: 0.43)

    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 18
    static let spacingXL: CGFloat = 24
    static let cardRadius: CGFloat = 16

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, Color(red: 0.04, green: 0.04, blue: 0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct ConcertRoot<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .tint(AppTheme.primaryAccent)
        .foregroundStyle(AppTheme.textPrimary)
    }
}

struct ConcertCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.spacingM)
            .background(AppTheme.surfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

extension View {
    func concertCard() -> some View { modifier(ConcertCardModifier()) }
}

struct PrimaryConcertButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                LinearGradient(
                    colors: [AppTheme.primaryAccent.opacity(configuration.isPressed ? 0.65 : 0.9), AppTheme.secondaryAccent.opacity(configuration.isPressed ? 0.55 : 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(AppTheme.textPrimary)
            .clipShape(Capsule())
    }
}

struct AccentBadge: View {
    let text: String
    let tone: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tone.opacity(0.2))
            .foregroundStyle(tone)
            .clipShape(Capsule())
    }
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.hasReadAccess {
                MainTabView()
            } else {
                PermissionView()
            }
        }
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
        .tint(AppTheme.primaryAccent)
        .overlay(alignment: .bottom) {
            if !appState.statusMessage.isEmpty {
                Text(appState.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.surface.opacity(0.95))
                    .overlay(Capsule().stroke(AppTheme.divider, lineWidth: 1))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
            }
        }
    }
}
