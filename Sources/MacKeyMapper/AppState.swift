import SwiftUI
import MacKeyMapperCore

enum AppMode {
    case scan
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
    @Published var theme: Theme = .dark
    @Published private(set) var scanned: ScannedKeyboard? = nil
    @Published private(set) var scanSession: ScanSession? = nil

    private let scanStore = ScanStore(fileURL: ScanStore.defaultURL())
    private let themeDefaultsKey = "themeID"
    let catalog = KeyCatalog.keys
    private let store = RemapStore(fileURL: RemapStore.defaultURL())
    private let monitor = KeyEventMonitor()

    func start() {
        accessibilityTrusted = Permissions.isTrusted()
        theme = Theme.by(id: UserDefaults.standard.string(forKey: themeDefaultsKey))
        mappings = (try? store.load()) ?? []
        scanned = try? scanStore.load()
        monitor.onEvent = { [weak self] code, isDown, isModifier, characters in
            Task { @MainActor in
                self?.handleKey(code: code, isDown: isDown, isModifier: isModifier, characters: characters)
            }
        }
        monitor.start()
    }

    func setTheme(_ t: Theme) {
        theme = t
        UserDefaults.standard.set(t.id, forKey: themeDefaultsKey)
    }

    func refreshPermission() {
        accessibilityTrusted = Permissions.isTrusted()
        // If permission was just granted, retry the event tap. start() only acts when
        // tap == nil, so if tap creation previously failed due to missing permission,
        // detection turns on immediately without needing a relaunch.
        if accessibilityTrusted {
            monitor.start()
        }
    }

    private func handleKey(code: UInt16, isDown: Bool, isModifier: Bool, characters: String) {
        if scanSession != nil {
            if isModifier {
                // flagsChanged fires on both press and release; capture on press only.
                if pressedKeyCodes.contains(code) {
                    pressedKeyCodes.remove(code)   // release — ignore
                } else {
                    pressedKeyCodes.insert(code)   // press — capture
                    scanSession?.record(keyCode: code, character: characters)
                    finishScanIfComplete()
                }
            } else if isDown {
                scanSession?.record(keyCode: code, character: characters)
                finishScanIfComplete()
            }
            return
        }
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
                pendingSourceID = nil   // press the same key again to cancel
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

    func startScan() {
        pressedKeyCodes = []
        scanSession = ScanSession()
    }

    func skipScanSlot() {
        scanSession?.skip()
        finishScanIfComplete()
    }

    func scanBack() {
        scanSession?.back()
        pressedKeyCodes = []   // re-pressing a modifier for the redone slot must register as a press
    }

    func cancelScan() {
        scanSession = nil
        pressedKeyCodes = []   // a modifier pressed mid-scan must not stay stuck in other modes
    }

    private func finishScanIfComplete() {
        guard let session = scanSession, session.isComplete else { return }
        let result = session.result()
        do {
            try scanStore.save(result)
            lastError = nil
        } catch {
            lastError = "\(error)"
        }
        scanned = result
        scanSession = nil
        pressedKeyCodes = []   // clear modifier-tracking state used during scan
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
