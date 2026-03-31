import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ConcertRoot {
                List {
                    sectionTitleRow("Processing")
                    Section {
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
                                .tint(AppTheme.primaryAccent)
                            Text(appState.settings.confidenceThreshold, format: .percent.precision(.fractionLength(0)))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.background)

                    sectionTitleRow("Video date range")
                    Section {
                        Toggle("Limit scan to date range", isOn: Binding(get: { appState.settings.videoDateFilterEnabled }, set: { value in update { $0.videoDateFilterEnabled = value } }))
                        if appState.settings.videoDateFilterEnabled {
                            dateRow(title: "On or after", date: appState.settings.videoDateRangeStart, placeholder: "Set start date", set: { d in update { $0.videoDateRangeStart = d } }, clear: { update { $0.videoDateRangeStart = nil } })
                            dateRow(title: "On or before", date: appState.settings.videoDateRangeEnd, placeholder: "Set end date", set: { d in update { $0.videoDateRangeEnd = d } }, clear: { update { $0.videoDateRangeEnd = nil } })
                        }
                    }
                    .listRowBackground(AppTheme.background)

                    sectionTitleRow("Library access")
                    Section {
                        Text("If access is limited, open iOS Settings > Privacy & Security > Photos > SetSnap and choose Full Access.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .listRowBackground(AppTheme.background)

                    sectionTitleRow("About")
                    Section {
                        Text("SetSnap is local-first. Detection and grouping are practical heuristics tuned for speed.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .listRowBackground(AppTheme.background)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .listSectionSeparator(.hidden)
                .listRowSeparatorTint(AppTheme.divider)
                .tint(AppTheme.primaryAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Settings")
        }
    }

    private func sectionTitleRow(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(AppTheme.background)
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
                    Button("Clear", action: clear)
                        .font(.caption)
                }
            }
            if let d = date {
                DatePicker(
                    title,
                    selection: Binding(get: { d }, set: { set($0) }),
                    displayedComponents: .date
                )
                .labelsHidden()
            } else {
                Button(placeholder) { set(Date()) }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.secondaryAccent)
            }
        }
        .padding(.vertical, 4)
    }
}
