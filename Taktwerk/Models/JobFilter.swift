import Foundation

enum SourceFilter: String, CaseIterable {
    case all = "All"
    case userAgent = "User"
    case systemAgent = "System"
    case systemDaemon = "Daemon"

    func matches(_ source: JobSource) -> Bool {
        switch self {
        case .all: true
        case .userAgent: source == .userAgent
        case .systemAgent: source == .systemAgent
        case .systemDaemon: source == .systemDaemon
        }
    }
}
