import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Processing") {
                    Toggle("Process only on Wi-Fi", isOn: Binding(get: { appState.settings.processOnlyOnWiFi }, set: { value in update { $0.processOnlyOnWiFi = value } }))
                    Toggle("Process only while charging", isOn: Binding(get: { appState.settings.processOnlyWhileCharging }, set: { value in update { $0.processOnlyWhileCharging = value } }))
                    Toggle("Favorites only", isOn: Binding(get: { appState.settings.favoritesOnly }, set: { value in update { $0.favoritesOnly = value } }))

                    Stepper(value: Binding(get: { Int(appState.settings.minimumVideoDuration) }, set: { value in update { $0.minimumVideoDuration = Double(value) } }), in: 5...120, step: 1) {
                        Text("Minimum video duration: \(Int(appState.settings.minimumVideoDuration))s")
                    }

                    Stepper(value: Binding(get: { appState.settings.maxAssetsPerBatch }, set: { value in update { $0.maxAssetsPerBatch = value } }), in: 5...200, step: 5) {
                        Text("Max assets per batch: \(appState.settings.maxAssetsPerBatch)")
                    }

                    VStack(alignment: .leading) {
                        Text("Concert confidence threshold")
                        Slider(value: Binding(get: { appState.settings.confidenceThreshold }, set: { value in update { $0.confidenceThreshold = value } }), in: 0.2...0.95)
                        Text(appState.settings.confidenceThreshold, format: .percent.precision(.fractionLength(0))).font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle("Limit scan to date range", isOn: Binding(get: { appState.settings.videoDateFilterEnabled }, set: { value in update { $0.videoDateFilterEnabled = value } }))
                    Text("Only videos created in this window are indexed and analyzed. Useful for large libraries.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if appState.settings.videoDateFilterEnabled {
                        dateRow(
                            title: "On or after",
                            date: appState.settings.videoDateRangeStart,
                            placeholder: "Set start date",
                            set: { d in update { $0.videoDateRangeStart = d } },
                            clear: { update { $0.videoDateRangeStart = nil } }
                        )
                        dateRow(
                            title: "On or before",
                            date: appState.settings.videoDateRangeEnd,
                            placeholder: "Set end date",
                            set: { d in update { $0.videoDateRangeEnd = d } },
                            clear: { update { $0.videoDateRangeEnd = nil } }
                        )
                        if appState.settings.videoDateRangeStart == nil && appState.settings.videoDateRangeEnd == nil {
                            Text("Set at least one date, or turn this off to scan all videos.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Video date range")
                }

                Section("Library Access") {
                    Text("If access is limited, open iOS Settings > Privacy & Security > Photos > SetSnap and choose Full Access for complete scanning.").font(.footnote).foregroundStyle(.secondary)
                }

                Section("About") {
                    Text("SetSnap runs local-first. Analysis and grouping are heuristic MVP logic and can improve over time.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func update(_ mutate: (inout AppSettings) -> Void) {
        var draft = appState.settings
        mutate(&draft)
        Task { await appState.updateSettings(draft) }
    }

    private func dateRow(
        title: String,
        date: Date?,
        placeholder: String,
        set: @escaping (Date?) -> Void,
        clear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                if date != nil {
                    Button("Clear", role: .none, action: clear)
                        .font(.caption)
                }
            }
            if let d = date {
                DatePicker(
                    title,
                    selection: Binding(
                        get: { d },
                        set: { set($0) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
            } else {
                Button(placeholder) {
                    set(Date())
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
