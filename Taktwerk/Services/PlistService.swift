import Foundation

actor PlistService {
    static let shared = PlistService()

    // MARK: - Directory scanning

    func scanPlistFiles() -> [(path: String, source: JobSource)] {
        var results: [(String, JobSource)] = []

        for (dir, source) in plistDirectories() {
            guard let entries = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil
            ) else { continue }

            for entry in entries where entry.pathExtension == "plist" {
                results.append((entry.path, source))
            }
        }
        return results
    }

    // MARK: - Parse plist

    func parsePlist(at path: String) throws -> PlistConfig {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)

        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw PlistError.notADictionary(path)
        }

        let label = (plist["Label"] as? String)
            ?? URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent

        let rawXML = try rawXMLString(from: data)

        return PlistConfig(
            label: label,
            program: plist["Program"] as? String,
            programArguments: plist["ProgramArguments"] as? [String],
            runAtLoad: plist["RunAtLoad"] as? Bool,
            keepAlive: plist["KeepAlive"] as? Bool,
            startInterval: (plist["StartInterval"] as? NSNumber)?.uint64Value,
            startCalendarInterval: parseCalendarIntervals(plist["StartCalendarInterval"]),
            standardOutPath: plist["StandardOutPath"] as? String,
            standardErrorPath: plist["StandardErrorPath"] as? String,
            workingDirectory: plist["WorkingDirectory"] as? String,
            environmentVariables: plist["EnvironmentVariables"] as? [String: String],
            disabled: plist["Disabled"] as? Bool,
            wakeSystem: plist["WakeSystem"] as? Bool,
            rawXML: rawXML
        )
    }

    // MARK: - Write plist

    func writePlist(to path: String, config: PlistConfig) throws {
        var dict: [String: Any] = [:]
        dict["Label"] = config.label

        if let program = config.program { dict["Program"] = program }
        if let args = config.programArguments { dict["ProgramArguments"] = args }
        if let runAtLoad = config.runAtLoad { dict["RunAtLoad"] = runAtLoad }
        if let keepAlive = config.keepAlive { dict["KeepAlive"] = keepAlive }
        if let interval = config.startInterval { dict["StartInterval"] = NSNumber(value: interval) }

        if let intervals = config.startCalendarInterval {
            dict["StartCalendarInterval"] = intervals.map { ci -> [String: Any] in
                var d: [String: Any] = [:]
                if let minute = ci.minute { d["Minute"] = NSNumber(value: minute) }
                if let hour = ci.hour { d["Hour"] = NSNumber(value: hour) }
                if let day = ci.day { d["Day"] = NSNumber(value: day) }
                if let weekday = ci.weekday { d["Weekday"] = NSNumber(value: weekday) }
                if let month = ci.month { d["Month"] = NSNumber(value: month) }
                return d
            }
        }

        if let path = config.standardOutPath { dict["StandardOutPath"] = path }
        if let path = config.standardErrorPath { dict["StandardErrorPath"] = path }
        if let wd = config.workingDirectory { dict["WorkingDirectory"] = wd }
        if let env = config.environmentVariables { dict["EnvironmentVariables"] = env }
        if let disabled = config.disabled { dict["Disabled"] = disabled }
        if let wake = config.wakeSystem { dict["WakeSystem"] = wake }

        let data = try PropertyListSerialization.data(
            fromPropertyList: dict,
            format: .xml,
            options: 0
        )
        try data.write(to: URL(fileURLWithPath: path))
    }

    // MARK: - Write raw XML

    func writeRawPlist(to path: String, xml: String) throws {
        guard let data = xml.data(using: .utf8) else {
            throw PlistError.invalidXML("Could not encode XML string")
        }
        // Validate by parsing
        _ = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        try data.write(to: URL(fileURLWithPath: path))
    }

    // MARK: - Parse XML string to PlistConfig

    func parseXMLString(_ xml: String) throws -> PlistConfig {
        guard let data = xml.data(using: .utf8) else {
            throw PlistError.invalidXML("Could not encode XML string")
        }

        guard let plist = try PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        ) as? [String: Any] else {
            throw PlistError.invalidXML("Plist is not a dictionary")
        }

        let label = (plist["Label"] as? String) ?? ""

        return PlistConfig(
            label: label,
            program: plist["Program"] as? String,
            programArguments: plist["ProgramArguments"] as? [String],
            runAtLoad: plist["RunAtLoad"] as? Bool,
            keepAlive: plist["KeepAlive"] as? Bool,
            startInterval: (plist["StartInterval"] as? NSNumber)?.uint64Value,
            startCalendarInterval: parseCalendarIntervals(plist["StartCalendarInterval"]),
            standardOutPath: plist["StandardOutPath"] as? String,
            standardErrorPath: plist["StandardErrorPath"] as? String,
            workingDirectory: plist["WorkingDirectory"] as? String,
            environmentVariables: plist["EnvironmentVariables"] as? [String: String],
            disabled: plist["Disabled"] as? Bool,
            wakeSystem: plist["WakeSystem"] as? Bool,
            rawXML: xml
        )
    }

    // MARK: - Serialize PlistConfig to XML string

    func configToXMLString(_ config: PlistConfig) throws -> String {
        var dict: [String: Any] = [:]
        dict["Label"] = config.label

        if let program = config.program { dict["Program"] = program }
        if let args = config.programArguments { dict["ProgramArguments"] = args }
        if let runAtLoad = config.runAtLoad { dict["RunAtLoad"] = runAtLoad }
        if let keepAlive = config.keepAlive { dict["KeepAlive"] = keepAlive }
        if let interval = config.startInterval { dict["StartInterval"] = NSNumber(value: interval) }

        if let intervals = config.startCalendarInterval {
            dict["StartCalendarInterval"] = intervals.map { ci -> [String: Any] in
                var d: [String: Any] = [:]
                if let minute = ci.minute { d["Minute"] = NSNumber(value: minute) }
                if let hour = ci.hour { d["Hour"] = NSNumber(value: hour) }
                if let day = ci.day { d["Day"] = NSNumber(value: day) }
                if let weekday = ci.weekday { d["Weekday"] = NSNumber(value: weekday) }
                if let month = ci.month { d["Month"] = NSNumber(value: month) }
                return d
            }
        }

        if let path = config.standardOutPath { dict["StandardOutPath"] = path }
        if let path = config.standardErrorPath { dict["StandardErrorPath"] = path }
        if let wd = config.workingDirectory { dict["WorkingDirectory"] = wd }
        if let env = config.environmentVariables { dict["EnvironmentVariables"] = env }
        if let disabled = config.disabled { dict["Disabled"] = disabled }
        if let wake = config.wakeSystem { dict["WakeSystem"] = wake }

        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Validate XML string

    func validateXML(_ xml: String) -> String? {
        guard let data = xml.data(using: .utf8) else {
            return "Could not encode XML string"
        }
        do {
            let result = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            if result is [String: Any] {
                return nil
            }
            return "Plist root must be a dictionary"
        } catch {
            return error.localizedDescription
        }
    }

    // MARK: - Create new agent

    func createAgent(label: String, config: PlistConfig) throws -> String {
        let agentsDir = userAgentsDirectory()
        try FileManager.default.createDirectory(at: agentsDir, withIntermediateDirectories: true)

        // Create log directories if needed (validated to be within home directory)
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        for logPath in [config.standardOutPath, config.standardErrorPath].compactMap({ $0 }) {
            let standardized = URL(fileURLWithPath: logPath).standardizedFileURL
            guard standardized.path.hasPrefix(homeDir) else {
                throw NSError(
                    domain: "PlistService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Log paths must be within home directory: \(logPath)"]
                )
            }
            let parent = standardized.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }

        let path = agentsDir.appendingPathComponent("\(label).plist").path
        try writePlist(to: path, config: config)
        return path
    }

    // MARK: - Delete agent

    func deleteAgent(at path: String) throws {
        let standardized = URL(fileURLWithPath: path).standardizedFileURL
        let allowedDir = userAgentsDirectory().standardizedFileURL.path

        guard standardized.path.hasPrefix(allowedDir),
              standardized.pathExtension == "plist" else {
            throw NSError(
                domain: "PlistService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Can only delete .plist files in ~/Library/LaunchAgents"]
            )
        }

        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
    }

    // MARK: - Helpers

    func userAgentsDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
    }

    func determineSource(for plistPath: String) -> JobSource {
        if plistPath.contains("/Library/LaunchDaemons") {
            return .systemDaemon
        } else if plistPath.hasPrefix("/Library/LaunchAgents") {
            return .systemAgent
        }
        return .userAgent
    }

    private func plistDirectories() -> [(URL, JobSource)] {
        var dirs: [(URL, JobSource)] = []

        let userAgents = userAgentsDirectory()
        dirs.append((userAgents, .userAgent))

        let systemAgents = URL(fileURLWithPath: "/Library/LaunchAgents")
        if FileManager.default.fileExists(atPath: systemAgents.path) {
            dirs.append((systemAgents, .systemAgent))
        }

        let systemDaemons = URL(fileURLWithPath: "/Library/LaunchDaemons")
        if FileManager.default.fileExists(atPath: systemDaemons.path) {
            dirs.append((systemDaemons, .systemDaemon))
        }

        return dirs
    }

    private func parseCalendarIntervals(_ value: Any?) -> [CalendarInterval]? {
        if let dict = value as? [String: Any] {
            return [parseOneInterval(dict)]
        }
        if let array = value as? [[String: Any]] {
            let intervals = array.map { parseOneInterval($0) }
            return intervals.isEmpty ? nil : intervals
        }
        return nil
    }

    private func parseOneInterval(_ dict: [String: Any]) -> CalendarInterval {
        CalendarInterval(
            minute: (dict["Minute"] as? NSNumber)?.uint32Value,
            hour: (dict["Hour"] as? NSNumber)?.uint32Value,
            day: (dict["Day"] as? NSNumber)?.uint32Value,
            weekday: (dict["Weekday"] as? NSNumber)?.uint32Value,
            month: (dict["Month"] as? NSNumber)?.uint32Value
        )
    }

    private func rawXMLString(from data: Data) throws -> String {
        // Check if already XML
        if let str = String(data: data, encoding: .utf8),
           str.hasPrefix("<?xml") || str.hasPrefix("<") {
            return str
        }
        // Binary plist: re-serialize to XML
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        let xmlData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        return String(data: xmlData, encoding: .utf8) ?? ""
    }
}

enum PlistError: LocalizedError {
    case notADictionary(String)
    case invalidXML(String)

    var errorDescription: String? {
        switch self {
        case .notADictionary(let path): "Plist at \(path) is not a dictionary"
        case .invalidXML(let reason): "Invalid plist XML: \(reason)"
        }
    }
}
