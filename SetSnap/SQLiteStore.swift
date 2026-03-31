import Foundation
import SQLite3

actor SQLiteStore {
    private var db: OpaquePointer?
    private let dbURL: URL

    init(filename: String = "setsnap.sqlite") throws {
        let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport.appendingPathComponent("SetSnap", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        dbURL = dir.appendingPathComponent(filename)
        try open(); try migrate()
    }

    deinit { if db != nil { sqlite3_close(db) } }

    private func open() throws {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            throw NSError(domain: "SQLiteStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open DB"])
        }
    }

    private func migrate() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS assets (
            id TEXT PRIMARY KEY,
            creationDate REAL,
            duration REAL NOT NULL,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            isFavorite INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            analysisStatus TEXT NOT NULL,
            recognitionStatus TEXT NOT NULL,
            snippetStatus TEXT NOT NULL,
            concertScore REAL NOT NULL,
            isLikelyConcert INTEGER NOT NULL,
            artistName TEXT,
            songTitle TEXT,
            recognitionConfidence REAL,
            eventID TEXT,
            eventTitle TEXT,
            lastError TEXT,
            analyzedAt REAL
        );
        CREATE TABLE IF NOT EXISTS snippets (
            id TEXT PRIMARY KEY,
            assetID TEXT NOT NULL,
            startTime REAL NOT NULL,
            endTime REAL NOT NULL,
            type TEXT NOT NULL,
            score REAL NOT NULL,
            exportedAt REAL,
            FOREIGN KEY(assetID) REFERENCES assets(id)
        );
        CREATE TABLE IF NOT EXISTS kv (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
        try execute(sql: sql)
    }

    private func execute(sql: String) throws {
        var error: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &error) != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? "Unknown SQLite error"
            sqlite3_free(error)
            throw NSError(domain: "SQLiteStore", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    func upsertAsset(_ asset: ClipAsset) {
        let sql = """
        INSERT INTO assets (
            id, creationDate, duration, width, height, isFavorite, latitude, longitude,
            analysisStatus, recognitionStatus, snippetStatus, concertScore, isLikelyConcert,
            artistName, songTitle, recognitionConfidence, eventID, eventTitle, lastError, analyzedAt
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            creationDate=excluded.creationDate,
            duration=excluded.duration,
            width=excluded.width,
            height=excluded.height,
            isFavorite=excluded.isFavorite,
            latitude=excluded.latitude,
            longitude=excluded.longitude,
            analysisStatus=excluded.analysisStatus,
            recognitionStatus=excluded.recognitionStatus,
            snippetStatus=excluded.snippetStatus,
            concertScore=excluded.concertScore,
            isLikelyConcert=excluded.isLikelyConcert,
            artistName=excluded.artistName,
            songTitle=excluded.songTitle,
            recognitionConfidence=excluded.recognitionConfidence,
            eventID=excluded.eventID,
            eventTitle=excluded.eventTitle,
            lastError=excluded.lastError,
            analyzedAt=excluded.analyzedAt;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, 1, asset.id)
        bindDouble(stmt, 2, asset.creationDate?.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 3, asset.duration)
        sqlite3_bind_int(stmt, 4, Int32(asset.width))
        sqlite3_bind_int(stmt, 5, Int32(asset.height))
        sqlite3_bind_int(stmt, 6, asset.isFavorite ? 1 : 0)
        bindDouble(stmt, 7, asset.latitude)
        bindDouble(stmt, 8, asset.longitude)
        bindText(stmt, 9, asset.analysisStatus.rawValue)
        bindText(stmt, 10, asset.recognitionStatus.rawValue)
        bindText(stmt, 11, asset.snippetStatus.rawValue)
        sqlite3_bind_double(stmt, 12, asset.concertScore)
        sqlite3_bind_int(stmt, 13, asset.isLikelyConcert ? 1 : 0)
        bindText(stmt, 14, asset.artistName)
        bindText(stmt, 15, asset.songTitle)
        bindDouble(stmt, 16, asset.recognitionConfidence)
        bindText(stmt, 17, asset.eventID)
        bindText(stmt, 18, asset.eventTitle)
        bindText(stmt, 19, asset.lastError)
        bindDouble(stmt, 20, asset.analyzedAt?.timeIntervalSince1970)
        sqlite3_step(stmt)
    }

    func replaceSnippets(for assetID: String, snippets: [ClipSnippet]) {
        try? execute(sql: "DELETE FROM snippets WHERE assetID = '\(assetID.replacingOccurrences(of: "'", with: "''"))';")
        let sql = "INSERT INTO snippets (id, assetID, startTime, endTime, type, score, exportedAt) VALUES (?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        for snippet in snippets {
            sqlite3_reset(stmt)
            bindText(stmt, 1, snippet.id)
            bindText(stmt, 2, snippet.assetID)
            sqlite3_bind_double(stmt, 3, snippet.startTime)
            sqlite3_bind_double(stmt, 4, snippet.endTime)
            bindText(stmt, 5, snippet.type.rawValue)
            sqlite3_bind_double(stmt, 6, snippet.score)
            bindDouble(stmt, 7, snippet.exportedAt?.timeIntervalSince1970)
            sqlite3_step(stmt)
        }
    }

    func markSnippetExported(id: String, at date: Date) {
        let sql = "UPDATE snippets SET exportedAt = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)
        bindText(stmt, 2, id)
        sqlite3_step(stmt)
    }

    func loadAssets() -> [ClipAsset] {
        let sql = "SELECT id, creationDate, duration, width, height, isFavorite, latitude, longitude, analysisStatus, recognitionStatus, snippetStatus, concertScore, isLikelyConcert, artistName, songTitle, recognitionConfidence, eventID, eventTitle, lastError, analyzedAt FROM assets ORDER BY creationDate DESC;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var output: [ClipAsset] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            output.append(ClipAsset(
                id: stringColumn(stmt, 0) ?? UUID().uuidString,
                creationDate: dateColumn(stmt, 1),
                duration: sqlite3_column_double(stmt, 2),
                width: Int(sqlite3_column_int(stmt, 3)),
                height: Int(sqlite3_column_int(stmt, 4)),
                isFavorite: sqlite3_column_int(stmt, 5) == 1,
                latitude: doubleColumn(stmt, 6),
                longitude: doubleColumn(stmt, 7),
                analysisStatus: AnalysisStatus(rawValue: stringColumn(stmt, 8) ?? "pending") ?? .pending,
                recognitionStatus: RecognitionStatus(rawValue: stringColumn(stmt, 9) ?? "pending") ?? .pending,
                snippetStatus: SnippetStatus(rawValue: stringColumn(stmt, 10) ?? "pending") ?? .pending,
                concertScore: sqlite3_column_double(stmt, 11),
                isLikelyConcert: sqlite3_column_int(stmt, 12) == 1,
                artistName: stringColumn(stmt, 13),
                songTitle: stringColumn(stmt, 14),
                recognitionConfidence: doubleColumn(stmt, 15),
                eventID: stringColumn(stmt, 16),
                eventTitle: stringColumn(stmt, 17),
                lastError: stringColumn(stmt, 18),
                analyzedAt: dateColumn(stmt, 19)
            ))
        }
        return output
    }

    func loadSnippets() -> [ClipSnippet] {
        let sql = "SELECT id, assetID, startTime, endTime, type, score, exportedAt FROM snippets ORDER BY score DESC;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var output: [ClipSnippet] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            output.append(ClipSnippet(
                id: stringColumn(stmt, 0) ?? UUID().uuidString,
                assetID: stringColumn(stmt, 1) ?? "",
                startTime: sqlite3_column_double(stmt, 2),
                endTime: sqlite3_column_double(stmt, 3),
                type: SnippetType(rawValue: stringColumn(stmt, 4) ?? "short") ?? .short,
                score: sqlite3_column_double(stmt, 5),
                exportedAt: dateColumn(stmt, 6)
            ))
        }
        return output
    }

    func saveSettings(_ settings: AppSettings) {
        let dto = SettingsDTO(from: settings)
        let data = try? JSONEncoder().encode(dto)
        let value = data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let sql = "INSERT INTO kv (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, "appSettings")
        bindText(stmt, 2, value)
        sqlite3_step(stmt)
    }

    func loadSettings() -> AppSettings {
        let sql = "SELECT value FROM kv WHERE key = 'appSettings' LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return .default }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW,
              let value = stringColumn(stmt, 0),
              let data = value.data(using: .utf8),
              let dto = try? JSONDecoder().decode(SettingsDTO.self, from: data)
        else { return .default }
        return dto.toModel()
    }

    private func bindText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let value { sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT) }
        else { sqlite3_bind_null(stmt, index) }
    }

    private func bindDouble(_ stmt: OpaquePointer?, _ index: Int32, _ value: Double?) {
        if let value { sqlite3_bind_double(stmt, index, value) }
        else { sqlite3_bind_null(stmt, index) }
    }

    private func stringColumn(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard let c = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: c)
    }

    private func doubleColumn(_ stmt: OpaquePointer?, _ index: Int32) -> Double? {
        sqlite3_column_type(stmt, index) == SQLITE_NULL ? nil : sqlite3_column_double(stmt, index)
    }

    private func dateColumn(_ stmt: OpaquePointer?, _ index: Int32) -> Date? {
        guard let ts = doubleColumn(stmt, index) else { return nil }
        return Date(timeIntervalSince1970: ts)
    }
}

private struct SettingsDTO: Codable {
    let processOnlyOnWiFi: Bool
    let processOnlyWhileCharging: Bool
    let minimumVideoDuration: Double
    let favoritesOnly: Bool
    let maxAssetsPerBatch: Int
    let confidenceThreshold: Double
    let videoDateFilterEnabled: Bool?
    let videoDateRangeStart: Date?
    let videoDateRangeEnd: Date?

    init(from model: AppSettings) {
        processOnlyOnWiFi = model.processOnlyOnWiFi
        processOnlyWhileCharging = model.processOnlyWhileCharging
        minimumVideoDuration = model.minimumVideoDuration
        favoritesOnly = model.favoritesOnly
        maxAssetsPerBatch = model.maxAssetsPerBatch
        confidenceThreshold = model.confidenceThreshold
        videoDateFilterEnabled = model.videoDateFilterEnabled
        videoDateRangeStart = model.videoDateRangeStart
        videoDateRangeEnd = model.videoDateRangeEnd
    }

    func toModel() -> AppSettings {
        AppSettings(
            processOnlyOnWiFi: processOnlyOnWiFi,
            processOnlyWhileCharging: processOnlyWhileCharging,
            minimumVideoDuration: minimumVideoDuration,
            favoritesOnly: favoritesOnly,
            maxAssetsPerBatch: maxAssetsPerBatch,
            confidenceThreshold: confidenceThreshold,
            videoDateFilterEnabled: videoDateFilterEnabled ?? false,
            videoDateRangeStart: videoDateRangeStart,
            videoDateRangeEnd: videoDateRangeEnd
        )
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
