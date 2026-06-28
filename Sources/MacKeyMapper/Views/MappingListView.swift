import SwiftUI
import MacKeyMapperCore

struct MappingListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Active Remaps (\(state.mappings.count))").font(.headline)
                Spacer()
                Button("Reset All", role: .destructive) { state.clearAll() }
                    .disabled(state.mappings.isEmpty)
            }
            if state.mappings.isEmpty {
                Text("In Remap mode, click 'source key → target key' in order.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(state.mappings) { m in
                    HStack {
                        Text("\(label(m.sourceKeyID)) → \(label(m.destKeyID))")
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            state.removeMapping(m)
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    private func label(_ id: String) -> String {
        KeyCatalog.key(id: id).map { "\($0.label)(\($0.id))" } ?? id
    }
}
