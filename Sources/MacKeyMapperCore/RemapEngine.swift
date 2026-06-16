import Foundation

public enum RemapEngine {
    public static let launchAgentLabel = "com.mackeymapper.remap"

    /// hidutil `--set` 에 넘길 UserKeyMapping JSON 문자열.
    /// - Note: catalog 에 없는 key id 를 가진 매핑은 조용히 제외된다.
    ///   호출 전에 `validateMappings(_:catalog:)` 로 검증하는 것을 전제로 한다.
    public static func userKeyMappingJSON(for mappings: [KeyMapping],
                                          catalog: [KeyDefinition] = KeyCatalog.keys) -> String {
        let lookup = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0.hidUsage) })
        let entries = mappings.compactMap { m -> String? in
            guard let src = lookup[m.sourceKeyID], let dst = lookup[m.destKeyID] else { return nil }
            return "{\"HIDKeyboardModifierMappingSrc\":\(src),\"HIDKeyboardModifierMappingDst\":\(dst)}"
        }
        return "{\"UserKeyMapping\":[\(entries.joined(separator: ","))]}"
    }

    public static func hidutilArguments(for mappings: [KeyMapping],
                                        catalog: [KeyDefinition] = KeyCatalog.keys) -> [String] {
        ["property", "--set", userKeyMappingJSON(for: mappings, catalog: catalog)]
    }

    public static func clearArguments() -> [String] {
        ["property", "--set", "{\"UserKeyMapping\":[]}"]
    }

    public static func launchAgentPlist(arguments: [String]) -> String {
        let argXML = (["/usr/bin/hidutil"] + arguments)
            .map { arg -> String in
                let escaped = arg
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                return "        <string>\(escaped)</string>"
            }
            .joined(separator: "\n")
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(launchAgentLabel)</string>
            <key>ProgramArguments</key>
            <array>
        \(argXML)
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """
    }
}
