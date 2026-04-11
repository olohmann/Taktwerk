import Foundation

struct LogContent: Sendable {
    let content: String
    let modifiedAt: Date?
}

actor LogService {
    static let shared = LogService()

    func readLog(at path: String, tailLines: Int? = nil) throws -> LogContent {
        guard FileManager.default.fileExists(atPath: path) else {
            throw LogError.fileNotFound(path)
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let modifiedAt = attrs[.modificationDate] as? Date

        let content = try String(contentsOfFile: path, encoding: .utf8)

        if let tailLines {
            let lines = content.components(separatedBy: "\n")
            let start = max(0, lines.count - tailLines)
            return LogContent(
                content: lines[start...].joined(separator: "\n"),
                modifiedAt: modifiedAt
            )
        }

        return LogContent(content: content, modifiedAt: modifiedAt)
    }

    func clearLog(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw LogError.fileNotFound(path)
        }
        try "".write(toFile: path, atomically: true, encoding: .utf8)
    }

    func openInEditor(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-t", path]
        try? process.run()
    }

    func revealInFinder(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-R", path]
        try? process.run()
    }
}

enum LogError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path): "Log file not found: \(path)"
        }
    }
}
