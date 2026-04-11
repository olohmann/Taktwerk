import Foundation

struct LoadedService: Sendable {
    let label: String
    let pid: UInt32?
    let lastExitCode: Int32?
}

actor LaunchctlService {
    static let shared = LaunchctlService()

    private var uid: uid_t {
        getuid()
    }

    private var guiTarget: String {
        "gui/\(uid)"
    }

    private func serviceTarget(label: String) -> String {
        "\(guiTarget)/\(label)"
    }

    // MARK: - List loaded services

    func listLoaded() async throws -> [LoadedService] {
        let output = try await run("launchctl", arguments: ["list"])
        return Self.parseListOutput(output)
    }

    static func parseListOutput(_ output: String) -> [LoadedService] {
        var services: [LoadedService] = []
        for line in output.split(separator: "\n").dropFirst() {
            let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard parts.count >= 3 else { continue }
            let pid = UInt32(parts[0].trimmingCharacters(in: .whitespaces))
            let exitCode = Int32(parts[1].trimmingCharacters(in: .whitespaces))
            let label = parts[2].trimmingCharacters(in: .whitespaces)
            guard !label.isEmpty else { continue }
            services.append(LoadedService(label: label, pid: pid, lastExitCode: exitCode))
        }
        return services
    }

    // MARK: - Bootstrap (load/start)

    func bootstrap(plistPath: String) async throws {
        do {
            try await run("launchctl", arguments: ["bootstrap", guiTarget, plistPath])
        } catch let error as LaunchctlError {
            if error.stderr.contains("already loaded") || error.stderr.contains("service already loaded") {
                return
            }
            throw error
        }
    }

    // MARK: - Bootout (unload/stop)

    func bootout(plistPath: String) async throws {
        do {
            try await run("launchctl", arguments: ["bootout", guiTarget, plistPath])
        } catch let error as LaunchctlError {
            if error.stderr.contains("not loaded")
                || error.stderr.contains("No such process")
                || error.stderr.contains("Could not find specified service") {
                return
            }
            throw error
        }
    }

    // MARK: - Kickstart (immediate test run)

    func kickstart(label: String) async throws {
        try await run("launchctl", arguments: ["kickstart", "-k", serviceTarget(label: label)])
    }

    // MARK: - Enable / Disable

    func enable(label: String) async throws {
        try await run("launchctl", arguments: ["enable", serviceTarget(label: label)])
    }

    func disable(label: String) async throws {
        try await run("launchctl", arguments: ["disable", serviceTarget(label: label)])
    }

    // MARK: - Compound operations

    func start(plistPath: String) async throws {
        try? await bootout(plistPath: plistPath)
        try await bootstrap(plistPath: plistPath)
    }

    func stop(plistPath: String) async throws {
        try await bootout(plistPath: plistPath)
    }

    func restart(plistPath: String) async throws {
        try? await bootout(plistPath: plistPath)
        try await bootstrap(plistPath: plistPath)
    }

    // MARK: - Process runner

    @discardableResult
    private func run(_ command: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            // Resolve the executable path — try common locations
            let searchPaths = ["/bin/\(command)", "/usr/bin/\(command)", "/usr/sbin/\(command)"]
            guard let execPath = searchPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
                continuation.resume(throwing: LaunchctlError(
                    message: "\(command) not found in \(searchPaths.joined(separator: ", "))",
                    stderr: ""
                ))
                return
            }

            process.executableURL = URL(fileURLWithPath: execPath)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: LaunchctlError(
                    message: "Failed to run \(command): \(error.localizedDescription)",
                    stderr: ""
                ))
                return
            }

            process.waitUntilExit()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                continuation.resume(throwing: LaunchctlError(
                    message: "\(command) \(arguments.joined(separator: " ")) failed (exit \(process.terminationStatus)): \(stderr)",
                    stderr: stderr
                ))
            } else {
                continuation.resume(returning: stdout)
            }
        }
    }
}

struct LaunchctlError: LocalizedError, Sendable {
    let message: String
    let stderr: String

    var errorDescription: String? { message }
}
