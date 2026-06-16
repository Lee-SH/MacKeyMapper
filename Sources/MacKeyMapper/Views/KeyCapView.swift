import SwiftUI
import MacKeyMapperCore

struct KeyCapView: View {
    let key: KeyDefinition
    let unit: CGFloat
    let isPressed: Bool
    let isPendingSource: Bool
    let mappedDestLabel: String?
    let onTap: () -> Void

    var body: some View {
        let w = unit * key.width
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(background)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(border, lineWidth: isPendingSource ? 2 : 1))
            VStack(spacing: 1) {
                Text(key.label).font(.system(size: 12, weight: .medium))
                if let name = key.name {
                    Text(name)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if let dest = mappedDestLabel {
                    Text("→\(dest)").font(.system(size: 9)).foregroundStyle(.blue)
                }
            }
            .padding(2)
        }
        .frame(width: w, height: unit)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var background: Color {
        if isPressed { return .accentColor.opacity(0.6) }
        if mappedDestLabel != nil { return .blue.opacity(0.12) }
        return Color(white: 0.18)
    }

    private var border: Color {
        isPendingSource ? .orange : Color(white: 0.35)
    }
}
