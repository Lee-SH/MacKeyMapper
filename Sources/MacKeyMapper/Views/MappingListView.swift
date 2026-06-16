import SwiftUI
import MacKeyMapperCore

struct MappingListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("적용된 리매핑 (\(state.mappings.count))").font(.headline)
                Spacer()
                Button("전체 초기화", role: .destructive) { state.clearAll() }
                    .disabled(state.mappings.isEmpty)
            }
            if state.mappings.isEmpty {
                Text("리매핑 모드에서 '원본 키 → 바꿀 키' 순서로 클릭하세요.")
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
