import SwiftUI

struct SnippetsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ConcertRoot {
                if appState.snippets.isEmpty {
                    VStack(spacing: AppTheme.spacingM) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 42))
                            .foregroundStyle(AppTheme.primaryAccent)
                        Text("No snippets yet")
                            .font(.title3.weight(.semibold))
                        Text("Run a scan to generate highlight snippets.")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(appState.snippets.sorted(by: { $0.score > $1.score })) { snippet in
                            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                                HStack {
                                    AccentBadge(text: snippet.type.rawValue.capitalized, tone: AppTheme.primaryAccent)
                                    Spacer()
                                    AccentBadge(text: snippet.score.formatted(.percent.precision(.fractionLength(0))), tone: AppTheme.secondaryAccent)
                                }
                                Text("\(snippet.startTime, specifier: "%.1f")s - \(snippet.endTime, specifier: "%.1f")s")
                                    .font(.subheadline.weight(.medium))
                                Text("Clip: \(snippet.assetID)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                                HStack {
                                    if snippet.exportedAt != nil {
                                        Label("Exported", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.success)
                                    }
                                    Spacer()
                                    Button("Export") {
                                        Task { await appState.export(snippet: snippet) }
                                    }
                                    .buttonStyle(PrimaryConcertButtonStyle())
                                }
                            }
                            .concertCard()
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .padding(.horizontal, AppTheme.spacingM)
                }
            }
            .navigationTitle("Snippets")
        }
    }
}
