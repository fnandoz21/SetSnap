import SwiftUI
import Photos

struct ThumbnailView: View {
    @EnvironmentObject private var appState: AppState
    let localIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.surface)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .tint(AppTheme.secondaryAccent)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AppTheme.divider, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: localIdentifier) { await loadThumbnail() }
    }

    private func loadThumbnail() async {
        guard let phAsset = appState.phAsset(for: localIdentifier) else { return }
        image = await PhotosService().requestThumbnail(for: phAsset, targetSize: CGSize(width: 220, height: 220))
    }
}
