import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !state.accessibilityTrusted {
                PermissionBanner()
            }

            HStack {
                Picker("모드", selection: $state.mode) {
                    Text("테스트").tag(AppMode.test)
                    Text("리매핑").tag(AppMode.remap)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                .onChange(of: state.mode) { _, _ in state.pendingSourceID = nil }

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
                    Label("테마: \(state.theme.name)", systemImage: "paintpalette")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if state.mode == .remap {
                Text(promptText)
                    .font(.callout)
                    .foregroundStyle(state.theme.pendingBorder)
            }

            KeyboardView()
            MappingListView()

            if let err = state.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(state.theme.windowBackground)
        .preferredColorScheme(state.theme.colorScheme)
    }

    private var promptText: String {
        if let src = state.pendingSourceID {
            return "'\(src)' 선택됨 — 바꿀 대상 키를 클릭하세요. (같은 키 재클릭 시 취소)"
        }
        return "원본 키를 클릭하세요."
    }
}
