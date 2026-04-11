import Foundation

enum JobSource: String, Codable, CaseIterable, Sendable {
    case userAgent = "UserAgent"
    case systemAgent = "SystemAgent"
    case systemDaemon = "SystemDaemon"

    var displayName: String {
        switch self {
        case .userAgent: "User"
        case .systemAgent: "System"
        case .systemDaemon: "Daemon"
        }
    }

    var isEditable: Bool {
        self == .userAgent
    }
}

enum JobStatus: String, Codable, Sendable {
    case running = "Running"
    case loaded = "Loaded"
    case unloaded = "Unloaded"
    case unknown = "Unknown"
}

struct LaunchdJob: Identifiable, Sendable {
    var id: String { plistPath }
    let label: String
    let plistPath: String
    let source: JobSource
    var status: JobStatus
    var pid: UInt32?
    var lastExitCode: Int32?
    var plistConfig: PlistConfig
}

struct JobListEntry: Identifiable, Sendable {
    var id: String { plistPath }
    let label: String
    var pid: UInt32?
    var lastExitCode: Int32?
    let plistPath: String
    let source: JobSource
    var status: JobStatus
}
