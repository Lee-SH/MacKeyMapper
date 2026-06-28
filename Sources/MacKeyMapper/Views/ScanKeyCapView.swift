import SwiftUI
import MacKeyMapperCore

struct ScanKeyCapView: View {
    let slot: ScanSlot
    let unit: CGFloat
    let captured: ScannedKey?      // nil = not scanned yet
    let isCurrent: Bool            // currently prompted slot during scanning
    let isPressed: Bool            // live highlight while viewing
    let theme: Theme

    var body: some View {
        let w = unit * CGFloat(slot.width)
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(background)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(border, lineWidth: isCurrent ? 2 : 1))
            VStack(spacing: 1) {
                Text(slot.macLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.labelColor)
                if let name = slot.macName {
                    Text(name)
                        .font(.system(size: 7))
                        .foregroundStyle(theme.nameColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                if let cap = captured, cap.present {
                    Text(rawValue(cap))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(2)
        }
        .frame(width: w, height: unit)
        .opacity(opacity)
    }

    private func rawValue(_ cap: ScannedKey) -> String {
        cap.character.isEmpty ? "#\(cap.keyCode)" : "\(cap.character) · \(cap.keyCode)"
    }

    private var background: Color {
        if isPressed { return theme.keyCapPressed }
        if let cap = captured, cap.present { return theme.keyCapMapped }
        return theme.keyCapBackground
    }

    private var border: Color {
        isCurrent ? theme.pendingBorder : theme.keyBorder
    }

    private var opacity: Double {
        if isCurrent { return 1.0 }
        if let cap = captured { return cap.present ? 1.0 : 0.25 }  // absent = faint
        return 0.4  // not yet scanned
    }
}
