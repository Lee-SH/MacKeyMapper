import SwiftUI
import MacKeyMapperCore

struct ScanView: View {
    @EnvironmentObject var state: AppState
    let unit: CGFloat = 48

    private var rows: [Int] {
        Array(Set(ScanTemplate.slots.map(\.row))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            controls
            keyboard
        }
    }

    @ViewBuilder
    private var controls: some View {
        if let session = state.scanSession {
            HStack(spacing: 10) {
                if let slot = session.currentSlot {
                    Text("Press the highlighted key: \(slot.macLabel)\(slot.macName.map { " (\($0))" } ?? "")")
                        .font(.callout).foregroundStyle(state.theme.pendingBorder)
                }
                Spacer()
                Text("\(session.index + 1) / \(session.slots.count)")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Skip") { state.skipScanSlot() }
                Button("Back") { state.scanBack() }.disabled(session.index == 0)
                Button("Cancel", role: .destructive) { state.cancelScan() }
            }
        } else if state.scanned == nil {
            HStack {
                Text("Scan your keyboard: press each highlighted key in order, or Skip keys you don't have.")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button("Start scan") { state.startScan() }
            }
        } else {
            HStack {
                Text("Your keyboard. Press a key to highlight it.")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button("Re-scan") { state.startScan() }
            }
        }
    }

    private var keyboard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(slots(in: row)) { slot in
                        ScanKeyCapView(
                            slot: slot,
                            unit: unit,
                            captured: captured(for: slot),
                            isCurrent: state.scanSession?.currentSlot?.id == slot.id,
                            isPressed: isPressed(slot),
                            theme: state.theme
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(state.theme.keyboardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func slots(in row: Int) -> [ScanSlot] {
        ScanTemplate.slots.filter { $0.row == row }
    }

    // While scanning, show captures accumulated so far; otherwise the saved board.
    private func captured(for slot: ScanSlot) -> ScannedKey? {
        if let session = state.scanSession {
            return session.result().key(forSlotID: slot.id)
        }
        return state.scanned?.key(forSlotID: slot.id)
    }

    private func isPressed(_ slot: ScanSlot) -> Bool {
        guard state.scanSession == nil,
              let cap = state.scanned?.key(forSlotID: slot.id), cap.present else { return false }
        return state.pressedKeyCodes.contains(cap.keyCode)
    }
}
