import SwiftUI
import MacKeyMapperCore

enum AppMode {
    case test
    case remap
}

@MainActor
final class AppState: ObservableObject {
    @Published var mode: AppMode = .test
    @Published var pressedKeyCodes: Set<UInt16> = []
    @Published var mappings: [KeyMapping] = []
    @Published var pendingSourceID: String? = nil
    @Published var accessibilityTrusted: Bool = false
    @Published var lastError: String? = nil

    let catalog = KeyCatalog.keys
    private let store = RemapStore(fileURL: RemapStore.defaultURL())
    private let monitor = KeyEventMonitor()

    func start() {
        accessibilityTrusted = Permissions.isTrusted()
        mappings = (try? store.load()) ?? []
        monitor.onEvent = { [weak self] code, isDown, isModifier in
            Task { @MainActor in
                self?.handleKey(code: code, isDown: isDown, isModifier: isModifier)
            }
        }
        monitor.start()
    }

    func refreshPermission() {
        accessibilityTrusted = Permissions.isTrusted()
        // 권한이 방금 허용됐다면 이벤트탭을 재시도한다. start()는 tap==nil 일 때만
        // 동작하므로, 이전에 권한 미허용으로 탭 생성에 실패한 경우 재실행 없이 즉시 감지가 켜진다.
        if accessibilityTrusted {
            monitor.start()
        }
    }

    private func handleKey(code: UInt16, isDown: Bool, isModifier: Bool) {
        if isModifier {
            if pressedKeyCodes.contains(code) {
                pressedKeyCodes.remove(code)
            } else {
                pressedKeyCodes.insert(code)
            }
        } else if isDown {
            pressedKeyCodes.insert(code)
        } else {
            pressedKeyCodes.remove(code)
        }
    }

    func keyTapped(_ key: KeyDefinition) {
        guard mode == .remap else { return }
        if let src = pendingSourceID {
            if src == key.id {
                pendingSourceID = nil   // 같은 키 다시 눌러 취소
            } else {
                addMapping(sourceID: src, destID: key.id)
                pendingSourceID = nil
            }
        } else {
            pendingSourceID = key.id
        }
    }

    func mapping(forSourceID id: String) -> KeyMapping? {
        mappings.first { $0.sourceKeyID == id }
    }

    private func addMapping(sourceID: String, destID: String) {
        var next = mappings.filter { $0.sourceKeyID != sourceID }
        next.append(KeyMapping(sourceKeyID: sourceID, destKeyID: destID))
        applyAndSave(next)
    }

    func removeMapping(_ m: KeyMapping) {
        applyAndSave(mappings.filter { $0.id != m.id })
    }

    func clearAll() {
        do {
            try RemapEngine.clearAll()
            try RemapEngine.removeLaunchAgent()
            try store.save([])
            mappings = []
            lastError = nil
        } catch {
            lastError = "\(error)"
        }
    }

    private func applyAndSave(_ next: [KeyMapping]) {
        do {
            try validateMappings(next)
            try RemapEngine.apply(next)
            try RemapEngine.installLaunchAgent(for: next)
            try store.save(next)
            mappings = next
            lastError = nil
        } catch {
            lastError = "\(error)"
        }
    }
}
