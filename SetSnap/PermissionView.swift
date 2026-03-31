import SwiftUI
import Photos

struct PermissionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.tv").font(.system(size: 58)).foregroundStyle(.indigo)
            Text("Welcome to SetSnap").font(.largeTitle).bold()
            Text("SetSnap needs Photos access to scan your videos, detect likely concert clips, suggest highlights, and save exported snippets back to your library.").multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal)
            Text("Limited access works, but full access gives complete-library scanning and better grouping.").font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Button { Task { await appState.requestPhotosAccess() } } label: {
                Text("Allow Photos Access").bold().frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).padding(.horizontal)

            if appState.authorizationStatus == .denied || appState.authorizationStatus == .restricted {
                Text("Photos access is denied. Open Settings > Privacy & Security > Photos and allow SetSnap.").font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center).padding(.horizontal)
            }
        }.padding()
    }
}
