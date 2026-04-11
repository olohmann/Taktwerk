import Foundation
import Observation

@Observable
@MainActor
final class JobEditorViewModel {
    var label = ""
    var program = ""
    var programArguments = ""
    var runAtLoad = true
    var keepAlive = false
    var scheduleType: ScheduleType = .none
    var startInterval: String = ""
    var calendarMinute: String = ""
    var calendarHour: String = ""
    var calendarDay: String = ""
    var calendarWeekday: Int? = nil
    var calendarMonth: String = ""
    var standardOutPath = ""
    var standardErrorPath = ""
    var workingDirectory = ""
    var environmentVariables: [(key: String, value: String)] = []
    var rawXML = ""
    var useRawEditor = false {
        didSet { handleEditorToggle(wasRaw: oldValue) }
    }

    var error: String?
    var saving = false
    var xmlValidationError: String?
    var plutilOutput: String?
    var validatingPlutil = false

    let isEditing: Bool
    let editingPlistPath: String?

    private let plistService = PlistService.shared

    enum ScheduleType: String, CaseIterable {
        case none = "None"
        case interval = "Interval"
        case calendar = "Calendar"
    }

    init(editingJob: LaunchdJob? = nil) {
        if let job = editingJob {
            isEditing = true
            editingPlistPath = job.plistPath
            let config = job.plistConfig
            label = config.label
            program = config.program ?? ""
            programArguments = (config.programArguments ?? []).joined(separator: "\n")
            runAtLoad = config.runAtLoad ?? false
            keepAlive = config.keepAlive ?? false
            standardOutPath = config.standardOutPath ?? ""
            standardErrorPath = config.standardErrorPath ?? ""
            workingDirectory = config.workingDirectory ?? ""
            rawXML = config.rawXML

            if let env = config.environmentVariables {
                environmentVariables = env.sorted(by: { $0.key < $1.key }).map { ($0.key, $0.value) }
            }

            if let interval = config.startInterval {
                scheduleType = .interval
                startInterval = "\(interval)"
            } else if let cal = config.startCalendarInterval?.first {
                scheduleType = .calendar
                if let m = cal.minute { calendarMinute = "\(m)" }
                if let h = cal.hour { calendarHour = "\(h)" }
                if let d = cal.day { calendarDay = "\(d)" }
                calendarWeekday = cal.weekday.map { Int($0) }
                if let mo = cal.month { calendarMonth = "\(mo)" }
            }
        } else {
            isEditing = false
            editingPlistPath = nil
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            standardOutPath = "\(home)/Library/Logs/"
            standardErrorPath = "\(home)/Library/Logs/"
        }
    }

    var isValid: Bool {
        if useRawEditor {
            return xmlValidationError == nil && !rawXML.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return !label.trimmingCharacters(in: .whitespaces).isEmpty
            && (!program.isEmpty || !programArguments.isEmpty)
    }

    // MARK: - Editor Toggle Sync

    private func handleEditorToggle(wasRaw: Bool) {
        if useRawEditor && !wasRaw {
            syncFormToXML()
        } else if !useRawEditor && wasRaw {
            syncXMLToForm()
        }
    }

    private func syncFormToXML() {
        let config = buildConfig()
        Task {
            do {
                rawXML = try await plistService.configToXMLString(config)
                xmlValidationError = nil
            } catch {
                // Keep existing rawXML if serialization fails
            }
        }
    }

    private func syncXMLToForm() {
        Task {
            do {
                let config = try await plistService.parseXMLString(rawXML)
                populateForm(from: config)
                xmlValidationError = nil
            } catch {
                self.error = "Could not parse XML: \(error.localizedDescription)"
            }
        }
    }

    private func populateForm(from config: PlistConfig) {
        label = config.label
        program = config.program ?? ""
        programArguments = (config.programArguments ?? []).joined(separator: "\n")
        runAtLoad = config.runAtLoad ?? false
        keepAlive = config.keepAlive ?? false
        standardOutPath = config.standardOutPath ?? ""
        standardErrorPath = config.standardErrorPath ?? ""
        workingDirectory = config.workingDirectory ?? ""

        if let env = config.environmentVariables {
            environmentVariables = env.sorted(by: { $0.key < $1.key }).map { ($0.key, $0.value) }
        } else {
            environmentVariables = []
        }

        if let interval = config.startInterval {
            scheduleType = .interval
            startInterval = "\(interval)"
            calendarMinute = ""
            calendarHour = ""
            calendarDay = ""
            calendarWeekday = nil
            calendarMonth = ""
        } else if let cal = config.startCalendarInterval?.first {
            scheduleType = .calendar
            startInterval = ""
            calendarMinute = cal.minute.map { "\($0)" } ?? ""
            calendarHour = cal.hour.map { "\($0)" } ?? ""
            calendarDay = cal.day.map { "\($0)" } ?? ""
            calendarWeekday = cal.weekday.map { Int($0) }
            calendarMonth = cal.month.map { "\($0)" } ?? ""
        } else {
            scheduleType = .none
            startInterval = ""
            calendarMinute = ""
            calendarHour = ""
            calendarDay = ""
            calendarWeekday = nil
            calendarMonth = ""
        }
    }

    // MARK: - XML Validation

    func validateXML() {
        Task {
            xmlValidationError = await plistService.validateXML(rawXML)
        }
    }

    // MARK: - plutil Validation

    func validateWithPlutil() async {
        validatingPlutil = true
        defer { validatingPlutil = false }

        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("taktwerk-validate-\(UUID().uuidString).plist")

        do {
            guard let data = rawXML.data(using: .utf8) else {
                plutilOutput = "Could not encode XML string"
                return
            }
            try data.write(to: tempFile)

            let result = try await runPlutil(path: tempFile.path)
            plutilOutput = result.isEmpty ? "✅ Valid plist" : result

            try? FileManager.default.removeItem(at: tempFile)
        } catch {
            plutilOutput = "Error: \(error.localizedDescription)"
            try? FileManager.default.removeItem(at: tempFile)
        }
    }

    private func runPlutil(path: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            let searchPaths = ["/usr/bin/plutil", "/bin/plutil"]
            guard let execPath = searchPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
                continuation.resume(returning: "plutil not found")
                return
            }

            process.executableURL = URL(fileURLWithPath: execPath)
            process.arguments = ["-lint", path]
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if process.terminationStatus == 0 {
                    continuation.resume(returning: "✅ \(output)")
                } else {
                    continuation.resume(returning: "❌ \(output)")
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Build & Save

    func buildConfig() -> PlistConfig {
        let args = programArguments
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var config = PlistConfig(
            label: label.trimmingCharacters(in: .whitespaces),
            program: program.isEmpty ? nil : program,
            programArguments: args.isEmpty ? nil : args,
            runAtLoad: runAtLoad,
            keepAlive: keepAlive,
            standardOutPath: standardOutPath.isEmpty ? nil : standardOutPath,
            standardErrorPath: standardErrorPath.isEmpty ? nil : standardErrorPath,
            workingDirectory: workingDirectory.isEmpty ? nil : workingDirectory,
            environmentVariables: nil,
            rawXML: rawXML
        )

        let env = environmentVariables.filter { !$0.key.isEmpty }
        if !env.isEmpty {
            config.environmentVariables = Dictionary(env.map { ($0.key, $0.value) }, uniquingKeysWith: { $1 })
        }

        switch scheduleType {
        case .none:
            break
        case .interval:
            config.startInterval = UInt64(startInterval)
        case .calendar:
            config.startCalendarInterval = [CalendarInterval(
                minute: UInt32(calendarMinute),
                hour: UInt32(calendarHour),
                day: UInt32(calendarDay),
                weekday: calendarWeekday.map { UInt32($0) },
                month: UInt32(calendarMonth)
            )]
        }

        return config
    }

    func save() async throws {
        saving = true
        defer { saving = false }

        if useRawEditor {
            guard let path = editingPlistPath else {
                throw PlistError.invalidXML("Cannot save raw XML for a new agent")
            }
            try await plistService.writeRawPlist(to: path, xml: rawXML)
        } else {
            let config = buildConfig()
            if let path = editingPlistPath {
                try await plistService.writePlist(to: path, config: config)
            } else {
                _ = try await plistService.createAgent(label: config.label, config: config)
            }
        }
    }
}
