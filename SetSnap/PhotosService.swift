import Foundation
import Photos
import AVFoundation
import UIKit

protocol PhotosServiceProtocol {
    func authorizationStatus() -> PHAuthorizationStatus
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchVideoAssets(
        favoritesOnly: Bool,
        minDuration: Double,
        dateFilterEnabled: Bool,
        dateRangeStart: Date?,
        dateRangeEnd: Date?
    ) -> [PHAsset]
    func requestAVAsset(for asset: PHAsset) async throws -> AVAsset
    func requestThumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage?
    func requestPlayerItem(for asset: PHAsset) async -> AVPlayerItem?
}

final class PhotosService: PhotosServiceProtocol {
    private let imageManager = PHCachingImageManager()

    func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchVideoAssets(
        favoritesOnly: Bool,
        minDuration: Double,
        dateFilterEnabled: Bool,
        dateRangeStart: Date?,
        dateRangeEnd: Date?
    ) -> [PHAsset] {
        let options = PHFetchOptions()
        var predicates: [NSPredicate] = [NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)]
        predicates.append(NSPredicate(format: "duration >= %f", minDuration))
        if favoritesOnly {
            predicates.append(NSPredicate(format: "favorite == YES"))
        }
        if dateFilterEnabled {
            let cal = Calendar.current
            var rawStart = dateRangeStart
            var rawEnd = dateRangeEnd
            if let a = rawStart, let b = rawEnd, cal.startOfDay(for: a) > cal.startOfDay(for: b) {
                swap(&rawStart, &rawEnd)
            }
            if let rs = rawStart {
                let start = cal.startOfDay(for: rs)
                predicates.append(NSPredicate(format: "creationDate >= %@", start as NSDate))
            }
            if let re = rawEnd {
                let startOfEndDay = cal.startOfDay(for: re)
                let endInclusive = cal.date(byAdding: DateComponents(day: 1, second: -1), to: startOfEndDay) ?? re
                predicates.append(NSPredicate(format: "creationDate <= %@", endInclusive as NSDate))
            }
        }
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    func requestAVAsset(for asset: PHAsset) async throws -> AVAsset {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.version = .original
            imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let avAsset else {
                    continuation.resume(throwing: NSError(domain: "PhotosService", code: 40, userInfo: [NSLocalizedDescriptionKey: "Unable to load AVAsset."]))
                    return
                }
                continuation.resume(returning: avAsset)
            }
        }
    }

    func requestThumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func requestPlayerItem(for asset: PHAsset) async -> AVPlayerItem? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .automatic
            options.isNetworkAccessAllowed = true
            options.version = .original
            imageManager.requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }
}
