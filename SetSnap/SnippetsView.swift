import SwiftUI

struct SnippetsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.snippets.sorted(by: { $0.score > $1.score })) { snippet in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(snippet.type.rawValue.capitalized).font(.headline)
                            Spacer()
                            Text(snippet.score, format: .percent.precision(.fractionLength(0))).foregroundStyle(.secondary)
                        }
                        Text("Clip: \(snippet.assetID)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        Text("\(snippet.startTime, specifier: "%.1f")s - \(snippet.endTime, specifier: "%.1f")s").font(.subheadline)
                        HStack {
                            if snippet.exportedAt != nil { Label("Exported", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.caption) }
                            Spacer()
                            Button("Export") { Task { await appState.export(snippet: snippet) } }.buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Snippets")
        }
    }
}
