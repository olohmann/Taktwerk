import SwiftUI

struct ContentView: View {
    @State private var viewModel = JobListViewModel()
    @State private var selectedPlistPath: String?
    @State private var showingEditor = false
    @State private var editingJob: LaunchdJob?
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Int = 60

    var body: some View {
        NavigationSplitView {
            JobListView(
                viewModel: viewModel,
                selectedPlistPath: $selectedPlistPath,
                onNewAgent: { showNewAgentEditor() },
                onEdit: { job in showEditor(for: job) }
            )
        } detail: {
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
            } else {
                ContentUnavailableView(
                    "No Agent Selected",
                    systemImage: "gearshape.2",
                    description: Text("Select an agent from the sidebar to view its details.")
                )
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
        .frame(minWidth: 700, minHeight: 400)
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
