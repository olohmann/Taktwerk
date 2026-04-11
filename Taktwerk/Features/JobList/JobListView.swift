import SwiftUI

struct JobListView: View {
    @Bindable var viewModel: JobListViewModel
    @Binding var selectedPlistPath: String?
    var onNewAgent: () -> Void
    var onEdit: (LaunchdJob) -> Void

    @State private var deleteTarget: JobListEntry?
    private let tagStore = TagStore.shared

    var body: some View {
        List(selection: $selectedPlistPath) {
            ForEach(viewModel.filteredJobs) { job in
                JobRowView(
                    job: job,
                    tags: tagStore.tags(for: job.label),
                    tagDefinitions: tagStore.tagDefinitions,
                    onStart: { Task { await viewModel.start(job) } },
                    onStop: { Task { await viewModel.stop(job) } },
                    onRestart: { Task { await viewModel.restart(job) } },
                    onKickstart: { Task { await viewModel.kickstart(job) } },
                    onDelete: { deleteTarget = job },
                    onRevealInFinder: { viewModel.revealInFinder(job) },
                    onToggleTag: { tagID in tagStore.toggleTag(id: tagID, on: job.label) }
                )
                .tag(job.plistPath)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search agents...")
        .toolbar {
            ToolbarItemGroup {
                Picker("Source", selection: $viewModel.sourceFilter) {
                    ForEach(SourceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                if !viewModel.availableTags.isEmpty {
                    Picker("Tag", selection: $viewModel.selectedTag) {
                        Text("All Tags").tag(nil as String?)
                        Divider()
                        ForEach(viewModel.availableTags) { tag in
                            Label(tag.name, systemImage: "tag.fill")
                                .foregroundStyle(tag.color)
                                .tag(tag.id as String?)
                        }
                    }
                    .frame(minWidth: 100)
                }

                Button {
                    viewModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)

                Button(action: onNewAgent) {
                    Label("New Agent", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .overlay {
            if viewModel.loading && viewModel.jobs.isEmpty {
                ProgressView("Loading agents...")
            }
        }
        .navigationTitle("Taktwerk")
        .navigationSubtitle(viewModel.jobCount)
        .safeAreaInset(edge: .bottom) {
            if viewModel.hasActiveFilters {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    if viewModel.sourceFilter != .all {
                        FilterChip(
                            label: viewModel.sourceFilter.rawValue,
                            icon: "folder",
                            color: .blue
                        ) {
                            viewModel.sourceFilter = .all
                        }
                    }

                    if let tagID = viewModel.selectedTag,
                       let def = viewModel.availableTags.first(where: { $0.id == tagID }) {
                        FilterChip(label: def.name, icon: "tag.fill", color: def.color) {
                            viewModel.selectedTag = nil
                        }
                    }

                    Spacer()

                    Button("Clear") {
                        viewModel.clearAllFilters()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.bar)
                .overlay(alignment: .top) { Divider() }
            }
        }
        .errorAlert($viewModel.error)
        .confirmationDialog(
            "Delete Agent",
            isPresented: .init(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            presenting: deleteTarget
        ) { job in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.delete(job)
                    if selectedPlistPath == job.plistPath {
                        selectedPlistPath = nil
                    }
                }
                deleteTarget = nil
            }
        } message: { job in
            Text("Are you sure you want to delete \"\(job.label)\"? This will stop the agent and remove its plist file.")
        }
    }
}
