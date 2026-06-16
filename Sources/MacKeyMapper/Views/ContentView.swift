import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !state.accessibilityTrusted {
                PermissionBanner()
            }
            Text("눌린 키코드: \(state.pressedKeyCodes.sorted().map(String.init).joined(separator: ", "))")
                .font(.system(.body, design: .monospaced))
            if let err = state.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
    }
}
