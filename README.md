# SetSnap

SetSnap is a local-first iOS app that scans your Photos video library, scores likely concert/music clips, attempts song recognition (ShazamKit when available), groups clips by artist/song/event, generates suggested snippets, and exports trimmed highlights back to Photos.

## Features

- SwiftUI iPhone app with tabs: Library, Artists, Events, Snippets, Settings
- PhotoKit authorization onboarding with limited-access guidance
- PhotoKit video indexing and iCloud-backed asset retrieval (`isNetworkAccessAllowed = true`)
- SQLite persistence for assets, snippets, statuses, and settings
- Heuristic concert-likelihood detection
- ShazamKit recognition when available (graceful fallback)
- Event grouping by time/location/artist hints
- Snippet generation (short / medium / hook estimate)
- AVAssetExportSession trim export, then save to Photos
- Incremental processing in batches with cancellation
- Optional **video date range** in Settings (limit which videos are fetched—helpful for very large libraries)
- Unit tests for core logic

## Open In Xcode

1. Open `SetSnap.xcodeproj` in Xcode 16+.
2. Select project `SetSnap` -> target `SetSnap` -> `Signing & Capabilities`.
3. Enable `Automatically manage signing`.
4. Pick your Apple ID team.
5. Change bundle id `com.example.SetSnap` to a unique id (for example `com.yourname.SetSnap`).
6. Connect iPhone, select it as run destination, and run.

## iPhone Install / Run Instructions

1. On iPhone, trust your Mac and enable Developer Mode if prompted.
2. Build and run from Xcode (`Product` -> `Run`).
3. On first app launch, tap **Allow Photos Access**.
4. Prefer **Full Access** for full-library scans (limited access still works).
5. In Library tab, tap **Scan**.
6. Review grouped clips in Artists / Events and snippets in Snippets tab.
7. Open clip/snippet and tap **Export** to save trimmed result back to Photos.

## Notes On Public APIs

- Photos integration: PhotoKit (`PHAsset`, `PHImageManager`, `PHPhotoLibrary`)
- Media analysis/export: AVFoundation (`AVAssetReader`, `AVAssetExportSession`)
- Song recognition: ShazamKit (`SHSession`) where available
- No private APIs
- No direct iCloud filesystem access

## Limitations

- Music recognition reliability varies with audio quality and entitlement availability.
- `Process only while charging` is persisted in settings but not hard-gated yet.
- Event naming is heuristic.
- Hook detection is energy-based (not ML chorus segmentation).

## Future Enhancements

- BGTaskScheduler background processing jobs
- Charging-state enforcement gate
- Better speech/music classifier via Core ML
- Manual event labeling and editing
- Smarter snippet diversification and dedupe
- Performance tuning for very large libraries

## Run Tests

- Xcode: `Product` -> `Test`
- Covered areas:
  - concert scoring trend validation
  - snippet range generation bounds
  - event grouping behavior
