import Foundation
import Observation

@Observable
@MainActor
final class JobListViewModel {
    var jobs: [JobListEntry] = []
    var loading = false
    var error: String?
    var searchText = ""
    var sourceFilter: SourceFilter = .all
    var selectedTag: String? = nil
    var refreshCounter = 0

    private let launchctl = LaunchctlService.shared
    private let plistService = PlistService.shared
    private let tagStore = TagStore.shared

    var filteredJobs: [JobListEntry] {
        jobs.filter { job in
            sourceFilter.matches(job.source)
            && (searchText.isEmpty || job.label.localizedCaseInsensitiveContains(searchText))
            && (selectedTag == nil || tagStore.hasTag(id: selectedTag!, on: job.label))
        }
    }

    var jobCount: String {
        let filtered = filteredJobs.count
        let total = jobs.count
        return filtered == total ? "\(total) agents" : "\(filtered) of \(total) agents"
    }

    var availableTags: [TagDefinition] {
        tagStore.tagDefinitions
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "defaultSourceFilter") ?? SourceFilter.all.rawValue
        sourceFilter = SourceFilter(rawValue: saved) ?? .all
        let savedTag = UserDefaults.standard.string(forKey: "defaultTagFilter")
        if let savedTag, tagStore.tagDefinitions.contains(where: { $0.id == savedTag }) {
            selectedTag = savedTag
        }
        Task { await loadJobs() }
    }

    var hasActiveFilters: Bool {
        sourceFilter != .all || selectedTag != nil
    }

    func clearAllFilters() {
        sourceFilter = .all
        selectedTag = nil
    }

    func refresh() {
        Task { await loadJobs() }
    }

    func loadJobs() async {
        loading = true
        error = nil
        do {
            let plistFiles = await plistService.scanPlistFiles()
            let loaded = try await launchctl.listLoaded()
            let loadedMap = Dictionary(loaded.map { ($0.label, $0) }, uniquingKeysWith: { $1 })

            var entries: [JobListEntry] = []
            for (path, source) in plistFiles {
                guard let config = try? await plistService.parsePlist(at: path) else { continue }

                let svc = loadedMap[config.label]
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

                entries.append(JobListEntry(
                    label: config.label,
                    pid: pid,
                    lastExitCode: exitCode,
                    plistPath: path,
                    source: source,
                    status: status
                ))
            }

            jobs = entries.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
        refreshCounter += 1
    }

    // MARK: - Actions

    func start(_ job: JobListEntry) async {
        guard job.source.isEditable else { return }
        do {
            try await launchctl.start(plistPath: job.plistPath)
            await loadJobs()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stop(_ job: JobListEntry) async {
        guard job.source.isEditable else { return }
        do {
            try await launchctl.stop(plistPath: job.plistPath)
            await loadJobs()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restart(_ job: JobListEntry) async {
        guard job.source.isEditable else { return }
        do {
            try await launchctl.restart(plistPath: job.plistPath)
            await loadJobs()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func kickstart(_ job: JobListEntry) async {
        guard job.source.isEditable else { return }
        do {
            let loaded = try await launchctl.listLoaded()
            if !loaded.contains(where: { $0.label == job.label }) {
                try await launchctl.bootstrap(plistPath: job.plistPath)
            }
            try await launchctl.kickstart(label: job.label)
            await loadJobs()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(_ job: JobListEntry) async {
        guard job.source.isEditable else { return }
        do {
            try? await launchctl.bootout(plistPath: job.plistPath)
            try? await launchctl.disable(label: job.label)
            try await plistService.deleteAgent(at: job.plistPath)
            await loadJobs()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func revealInFinder(_ job: JobListEntry) {
        Task { await LogService.shared.revealInFinder(path: job.plistPath) }
    }
}
