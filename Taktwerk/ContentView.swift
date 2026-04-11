import SwiftUI
import AppKit

struct ContentView: View {
    @State private var viewModel = JobListViewModel()
    @State private var selectedPlistPath: String?
    @State private var showingEditor = false
    @State private var editingJob: LaunchdJob?
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Int = 60
    @AppStorage("skippedUpdateVersion") private var skippedUpdateVersion: String = ""
    @State private var availableUpdate: AppUpdate?
    @State private var updateDismissed = false

    private var showUpdateBanner: Bool {
        guard let update = availableUpdate, !updateDismissed else { return false }
        return UpdateService.shouldShowUpdate(version: update.version, skippedVersion: skippedUpdateVersion)
    }

    var body: some View {
        NavigationSplitView {
            JobListView(
                viewModel: viewModel,
                selectedPlistPath: $selectedPlistPath,
                onNewAgent: { showNewAgentEditor() },
                onEdit: { job in showEditor(for: job) }
            )
        } detail: {
            VStack(spacing: 0) {
                if showUpdateBanner, let update = availableUpdate {
                    updateBanner(update)
                }

                if let plistPath = selectedPlistPath {
                    JobDetailView(
                        plistPath: plistPath,
                        refreshTrigger: viewModel.refreshCounter,
                        onEdit: { job in showEditor(for: job) },
                        onDeleted: {
                            selectedPlistPath = nil
                            viewModel.refresh()
                        }
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "No Agent Selected",
                        systemImage: "gearshape.2",
                        description: Text("Select an agent from the sidebar to view its details.")
                    )
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            JobEditorView(
                editingJob: editingJob,
                onSave: {
                    showingEditor = false
                    editingJob = nil
                    viewModel.refresh()
                },
                onCancel: {
                    showingEditor = false
                    editingJob = nil
                }
            )
        }
        .task(id: autoRefreshInterval) {
            guard autoRefreshInterval > 0 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(autoRefreshInterval))
                guard !Task.isCancelled else { break }
                viewModel.refresh()
            }
        }
        .task {
            await checkForUpdate()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3600))
                guard !Task.isCancelled else { break }
                await checkForUpdate()
            }
        }
        .frame(minWidth: 700, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .checkForUpdates)) { _ in
            Task { await forceCheckForUpdate() }
        }
    }

    @ViewBuilder
    private func updateBanner(_ update: AppUpdate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.blue)

            Text("Taktwerk v\(update.version) available")
                .font(.callout)
                .fontWeight(.medium)

            Spacer()

            Button("Release Notes") {
                NSWorkspace.shared.open(update.releaseURL)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .font(.caption)

            Button("Download") {
                NSWorkspace.shared.open(update.dmgURL)
            }
            .buttonStyle(.bordered)
            .font(.caption)

            Button("Quit & Update") {
                NSWorkspace.shared.open(update.dmgURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.caption)

            Button("Skip Version") {
                skippedUpdateVersion = update.version
                updateDismissed = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.08))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func checkForUpdate() async {
        if let update = await UpdateService.shared.checkForUpdate() {
            availableUpdate = update
            // Auto-clear skipped version if a newer version has appeared
            if !skippedUpdateVersion.isEmpty,
               UpdateService.isNewer(remote: update.version, current: skippedUpdateVersion) {
                skippedUpdateVersion = ""
            }
            updateDismissed = false
        }
    }

    func forceCheckForUpdate() async {
        let savedSkip = skippedUpdateVersion
        skippedUpdateVersion = ""
        if let update = await UpdateService.shared.checkForUpdate() {
            availableUpdate = update
            updateDismissed = false
        } else {
            skippedUpdateVersion = savedSkip
        }
    }

    private func showNewAgentEditor() {
        editingJob = nil
        showingEditor = true
    }

    private func showEditor(for job: LaunchdJob) {
        editingJob = job
        showingEditor = true
    }
}
