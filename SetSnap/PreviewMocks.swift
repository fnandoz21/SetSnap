import SwiftUI

struct PreviewMocks {
    static let clip = ClipAsset(
        id: "preview_clip",
        creationDate: Date(),
        duration: 42,
        width: 1920,
        height: 1080,
        isFavorite: true,
        latitude: nil,
        longitude: nil,
        analysisStatus: .completed,
        recognitionStatus: .matched,
        snippetStatus: .generated,
        concertScore: 0.84,
        isLikelyConcert: true,
        artistName: "Demo Artist",
        songTitle: "Demo Song",
        recognitionConfidence: 0.8,
        eventID: "event_preview",
        eventTitle: "Demo Night",
        lastError: nil,
        analyzedAt: Date()
    )
}

#Preview("Library") {
    LibraryView().environmentObject(AppState.bootstrap())
}
