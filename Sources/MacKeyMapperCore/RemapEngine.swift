import Foundation

public enum RemapEngine {
    public static let launchAgentLabel = "com.mackeymapper.remap"

    /// UserKeyMapping JSON string to pass to hidutil `--set`.
    /// - Note: Mappings whose key id is not in the catalog are silently dropped.
    ///   Assumes the caller has validated via `validateMappings(_:catalog:)` beforehand.
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

public enum RemapRuntimeError: Error, Equatable {
    case hidutilFailed(status: Int32, message: String)
}

extension RemapEngine {
    @discardableResult
    static func runHidutil(_ arguments: [String]) throws -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        proc.arguments = arguments
        let errPipe = Pipe()
        proc.standardError = errPipe
        proc.standardOutput = Pipe()
        try proc.run()
        proc.waitUntilExit()
        if proc.terminationStatus != 0 {
            let msg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                             encoding: .utf8) ?? ""
            throw RemapRuntimeError.hidutilFailed(status: proc.terminationStatus, message: msg)
        }
        return proc.terminationStatus
    }

    public static func apply(_ mappings: [KeyMapping],
                             catalog: [KeyDefinition] = KeyCatalog.keys) throws {
        try runHidutil(hidutilArguments(for: mappings, catalog: catalog))
    }

    public static func clearAll() throws {
        try runHidutil(clearArguments())
    }

    public static func launchAgentURL() -> URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaunchAgents/\(launchAgentLabel).plist")
    }

    public static func installLaunchAgent(for mappings: [KeyMapping],
                                          catalog: [KeyDefinition] = KeyCatalog.keys) throws {
        let url = launchAgentURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let plist = launchAgentPlist(arguments: hidutilArguments(for: mappings, catalog: catalog))
        try plist.write(to: url, atomically: true, encoding: .utf8)
    }

    public static func removeLaunchAgent() throws {
        let url = launchAgentURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
