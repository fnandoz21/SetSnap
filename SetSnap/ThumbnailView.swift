import SwiftUI
import Photos

struct ThumbnailView: View {
    @EnvironmentObject private var appState: AppState
    let localIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Rectangle().fill(Color.secondary.opacity(0.15)); ProgressView() }
        }
        .task(id: localIdentifier) { await loadThumbnail() }
    }

    private func loadThumbnail() async {
        guard let phAsset = appState.phAsset(for: localIdentifier) else { return }
        image = await PhotosService().requestThumbnail(for: phAsset, targetSize: CGSize(width: 220, height: 220))
    }
}
