import SwiftUI

struct PermissionBanner: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("Key detection requires Input Monitoring permission. Grant it, then relaunch the app.")
                .font(.callout)
            Spacer()
            Button("Open Settings") { Permissions.promptAndOpenSettings() }
            Button("Re-check") { state.refreshPermission() }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
