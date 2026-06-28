import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !state.inputMonitoringGranted {
                PermissionBanner()
            }

            HStack {
                Picker("Mode", selection: $state.mode) {
                    Text("Scan").tag(AppMode.scan)
                    Text("Test").tag(AppMode.test)
                    Text("Remap").tag(AppMode.remap)
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
                .onChange(of: state.mode) { _, newMode in
                    state.pendingSourceID = nil
                    if newMode != .scan { state.cancelScan() }   // don't let a scan linger and hijack other modes
                }

                Spacer()

                Menu {
                    ForEach(Theme.all) { t in
                        Button {
                            state.setTheme(t)
                        } label: {
                            if t.id == state.theme.id {
                                Label(t.name, systemImage: "checkmark")
                            } else {
                                Text(t.name)
                            }
                        }
                    }
                } label: {
                    Label("Theme: \(state.theme.name)", systemImage: "paintpalette")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if state.mode == .scan {
                ScanView()
            } else {
                if state.mode == .remap {
                    Text(promptText)
                        .font(.callout)
                        .foregroundStyle(state.theme.pendingBorder)
                }

                KeyboardView()
                MappingListView()
            }

            if let err = state.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
        .background(state.theme.windowBackground)
        .preferredColorScheme(state.theme.colorScheme)
    }

    private var promptText: String {
        if let src = state.pendingSourceID {
            return "'\(src)' selected — click the target key to map to. (Click the same key again to cancel)"
        }
        return "Click the source key."
    }
}
