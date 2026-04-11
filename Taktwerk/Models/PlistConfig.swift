import Foundation

struct CalendarInterval: Codable, Sendable, Equatable {
    var minute: UInt32?
    var hour: UInt32?
    var day: UInt32?
    var weekday: UInt32?
    var month: UInt32?

    var summary: String {
        var parts: [String] = []
        if let month { parts.append("Month: \(month)") }
        if let day { parts.append("Day: \(day)") }
        if let weekday { parts.append("Weekday: \(weekdayName(weekday))") }
        if let hour { parts.append("Hour: \(hour)") }
        if let minute { parts.append("Minute: \(minute)") }
        return parts.isEmpty ? "Every run" : parts.joined(separator: ", ")
    }

    private func weekdayName(_ day: UInt32) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard day < names.count else { return "\(day)" }
        return names[Int(day)]
    }
}

struct PlistConfig: Sendable {
    var label: String
    var program: String?
    var programArguments: [String]?
    var runAtLoad: Bool?
    var keepAlive: Bool?
    var startInterval: UInt64?
    var startCalendarInterval: [CalendarInterval]?
    var standardOutPath: String?
    var standardErrorPath: String?
    var workingDirectory: String?
    var environmentVariables: [String: String]?
    var disabled: Bool?
    var wakeSystem: Bool?
    var rawXML: String

    var effectiveCommand: String {
        if let args = programArguments, !args.isEmpty {
            return args.joined(separator: " ")
        }
        return program ?? "(no command)"
    }

    var hasSchedule: Bool {
        startInterval != nil || startCalendarInterval != nil
    }

    var hasLogs: Bool {
        standardOutPath != nil || standardErrorPath != nil
    }

    static var empty: PlistConfig {
        PlistConfig(
            label: "",
            rawXML: ""
        )
    }
}
