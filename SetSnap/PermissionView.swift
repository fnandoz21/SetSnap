import SwiftUI
import Photos

struct PermissionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ConcertRoot {
            VStack(spacing: AppTheme.spacingXL) {
                Spacer(minLength: 20)

                Image(systemName: "music.note.tv")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                VStack(spacing: AppTheme.spacingM) {
                    Text("Welcome to SetSnap")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("SetSnap needs Photos access to scan concert clips, group by artist and event, and export highlights back to your library.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Limited access works, but Full Access gives the best results for complete-library scanning.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppTheme.spacingXL)

                Button {
                    Task { await appState.requestPhotosAccess() }
                } label: {
                    Text("Allow Photos Access")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryConcertButtonStyle())
                .padding(.horizontal, AppTheme.spacingXL)

                if appState.authorizationStatus == .denied || appState.authorizationStatus == .restricted {
                    Text("Access denied. Open iOS Settings > Privacy & Security > Photos and allow SetSnap.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.spacingXL)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
