import Foundation

protocol EventGroupingServiceProtocol {
    func inferEventGroups(from assets: [ClipAsset]) -> [EventGroup]
}

struct EventGroupingService: EventGroupingServiceProtocol {
    func inferEventGroups(from assets: [ClipAsset]) -> [EventGroup] {
        let candidates = assets.filter { $0.isLikelyConcert }.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        guard !candidates.isEmpty else { return [] }
        var groups: [[ClipAsset]] = [[candidates[0]]]

        for clip in candidates.dropFirst() {
            guard var lastGroup = groups.last, let lastClip = lastGroup.last, let clipDate = clip.creationDate, let lastDate = lastClip.creationDate else {
                groups.append([clip]); continue
            }
            let timeDiff = abs(clipDate.timeIntervalSince(lastDate))
            let sameNightWindow = timeDiff <= (6 * 60 * 60)
            let sameArea = locationDistanceMeters(a: clip, b: lastClip).map { $0 < 1500 } ?? true
            let artistCompatible = clip.artistName == nil || lastClip.artistName == nil || clip.artistName == lastClip.artistName

            if sameNightWindow && sameArea && artistCompatible {
                lastGroup.append(clip); groups[groups.count - 1] = lastGroup
            } else { groups.append([clip]) }
        }

        return groups.enumerated().map { index, clips in
            let start = clips.compactMap(\.creationDate).min() ?? Date()
            let end = clips.compactMap(\.creationDate).max() ?? start
            let artistHint = clips.compactMap(\.artistName).first
            let f = DateFormatter(); f.dateStyle = .medium
            let title = artistHint.map { "\($0) - \(f.string(from: start))" } ?? "Concert Night \(index + 1)"
            return EventGroup(id: "event_\(index)_\(Int(start.timeIntervalSince1970))", title: title, dateStart: start, dateEnd: end, artistHint: artistHint, assetIDs: clips.map(\.id))
        }
    }

    private func locationDistanceMeters(a: ClipAsset, b: ClipAsset) -> Double? {
        guard let aLat = a.latitude, let aLon = a.longitude, let bLat = b.latitude, let bLon = b.longitude else { return nil }
        let earthRadius = 6_371_000.0
        let dLat = (bLat - aLat) * .pi / 180
        let dLon = (bLon - aLon) * .pi / 180
        let lat1 = aLat * .pi / 180
        let lat2 = bLat * .pi / 180
        let x = sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
        let c = 2 * atan2(sqrt(x), sqrt(1 - x))
        return earthRadius * c
    }
}
