import SwiftUI
import MacKeyMapperCore

struct KeyboardView: View {
    @EnvironmentObject var state: AppState
    let unit: CGFloat = 46

    private var rows: [Int] {
        Array(Set(state.catalog.map(\.row))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(keys(in: row)) { key in
                        KeyCapView(
                            key: key,
                            unit: unit,
                            isPressed: state.pressedKeyCodes.contains(key.virtualKeyCode),
                            isPendingSource: state.pendingSourceID == key.id,
                            mappedDestLabel: destLabel(for: key),
                            onTap: { state.keyTapped(key) }
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func keys(in row: Int) -> [KeyDefinition] {
        state.catalog.filter { $0.row == row }
    }

    private func destLabel(for key: KeyDefinition) -> String? {
        guard let m = state.mapping(forSourceID: key.id),
              let dest = KeyCatalog.key(id: m.destKeyID) else { return nil }
        return dest.label
    }
}
