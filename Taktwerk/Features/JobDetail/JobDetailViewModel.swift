import Foundation
import Observation

@Observable
@MainActor
final class JobDetailViewModel {
    var job: LaunchdJob?
    var loading = false
    var error: String?

    private let plistService = PlistService.shared
    private let launchctl = LaunchctlService.shared

    func loadDetail(plistPath: String) async {
        loading = true
        error = nil
        do {
            let config = try await plistService.parsePlist(at: plistPath)
            let loaded = try await launchctl.listLoaded()
            let svc = loaded.first { $0.label == config.label }

            let status: JobStatus
            let pid: UInt32?
            let exitCode: Int32?

            if let svc {
                status = svc.pid != nil ? .running : .loaded
                pid = svc.pid
                exitCode = svc.lastExitCode
            } else {
                status = .unloaded
                pid = nil
                exitCode = nil
            }

            let source = await plistService.determineSource(for: plistPath)

            job = LaunchdJob(
                label: config.label,
                plistPath: plistPath,
                source: source,
                status: status,
                pid: pid,
                lastExitCode: exitCode,
                plistConfig: config
            )
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func start() async {
        guard let job, job.source.isEditable else { return }
        do {
            try await launchctl.start(plistPath: job.plistPath)
            await loadDetail(plistPath: job.plistPath)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stop() async {
        guard let job, job.source.isEditable else { return }
        do {
            try await launchctl.stop(plistPath: job.plistPath)
            await loadDetail(plistPath: job.plistPath)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restart() async {
        guard let job, job.source.isEditable else { return }
        do {
            try await launchctl.restart(plistPath: job.plistPath)
            await loadDetail(plistPath: job.plistPath)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func kickstart() async {
        guard let job, job.source.isEditable else { return }
        do {
            let loaded = try await launchctl.listLoaded()
            if !loaded.contains(where: { $0.label == job.label }) {
                try await launchctl.bootstrap(plistPath: job.plistPath)
            }
            try await launchctl.kickstart(label: job.label)
            await loadDetail(plistPath: job.plistPath)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func revealInFinder() {
        guard let job else { return }
        Task { await LogService.shared.revealInFinder(path: job.plistPath) }
    }
}
