import SwiftUI

struct JobDetailView: View {
    let plistPath: String
    var refreshTrigger: Int = 0
    var onEdit: (LaunchdJob) -> Void
    var onDeleted: () -> Void

    @State private var viewModel = JobDetailViewModel()
    @State private var showDeleteConfirmation = false
    private let tagStore = TagStore.shared

    var body: some View {
        Group {
            if viewModel.loading && viewModel.job == nil {
                ProgressView("Loading...")
            } else if let job = viewModel.job {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection(job)
                        Divider()
                        PlistConfigView(config: job.plistConfig)
                        if job.plistConfig.hasSchedule {
                            Divider()
                            ScheduleView(config: job.plistConfig)
                        }
                        if job.plistConfig.hasLogs {
                            Divider()
                            LogViewerView(config: job.plistConfig)
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Could Not Load Details",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .task(id: "\(plistPath)-\(refreshTrigger)") {
            await viewModel.loadDetail(plistPath: plistPath)
        }
        .errorAlert($viewModel.error)
        .confirmationDialog(
            "Delete Agent",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if let job = viewModel.job {
                        try? await LaunchctlService.shared.bootout(plistPath: job.plistPath)
                        try? await LaunchctlService.shared.disable(label: job.label)
                        try? await PlistService.shared.deleteAgent(at: job.plistPath)
                        onDeleted()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this agent? This will stop it and remove the plist file.")
        }
    }

    @ViewBuilder
    private func headerSection(_ job: LaunchdJob) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.label)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)

                    HStack(spacing: 8) {
                        StatusBadge(status: job.status)
                        SourceBadge(source: job.source)
                        if let pid = job.pid {
                            Text("PID \(pid)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let exitCode = job.lastExitCode {
                            Text("Exit: \(exitCode)")
                                .font(.caption)
                                .foregroundColor(exitCode == 0 ? .secondary : .red)
                        }
                    }

                    // Tags
                    HStack(spacing: 4) {
                        ForEach(tagStore.tags(for: job.label)) { tag in
                            TagBadge(tag: tag)
                                .onTapGesture {
                                    tagStore.removeTag(id: tag.id, from: job.label)
                                }
                        }

                        if !tagStore.tagDefinitions.isEmpty {
                            Menu {
                                ForEach(tagStore.tagDefinitions) { tag in
                                    Button {
                                        tagStore.toggleTag(id: tag.id, on: job.label)
                                    } label: {
                                        HStack {
                                            Text(tag.name)
                                            if tagStore.hasTag(id: tag.id, on: job.label) {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }

                Spacer()

                actionButtons(job)
            }

            Text(job.plistPath)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func actionButtons(_ job: LaunchdJob) -> some View {
        HStack(spacing: 8) {
            if job.source.isEditable {
                Button("Start") { Task { await viewModel.start() } }
                Button("Stop") { Task { await viewModel.stop() } }
                Button("Restart") { Task { await viewModel.restart() } }

                Menu {
                    Button("Test Run (Kickstart)") { Task { await viewModel.kickstart() } }
                    Divider()
                    Button("Edit...") { onEdit(job) }
                    Button("Reveal in Finder") { viewModel.revealInFinder() }
                    Divider()
                    Button("Delete", role: .destructive) { showDeleteConfirmation = true }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            } else {
                Button("Reveal in Finder") { viewModel.revealInFinder() }
            }
        }
        .buttonStyle(.bordered)
    }
}
