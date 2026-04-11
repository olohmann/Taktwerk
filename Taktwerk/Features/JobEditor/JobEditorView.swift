import SwiftUI

struct JobEditorView: View {
    let editingJob: LaunchdJob?
    var onSave: () -> Void
    var onCancel: () -> Void

    @State private var viewModel: JobEditorViewModel

    init(editingJob: LaunchdJob?, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.editingJob = editingJob
        self.onSave = onSave
        self.onCancel = onCancel
        _viewModel = State(initialValue: JobEditorViewModel(editingJob: editingJob))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.isEditing ? "Edit Agent" : "New Agent")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()

                if viewModel.isEditing {
                    Toggle("Raw XML", isOn: $viewModel.useRawEditor)
                        .toggleStyle(.switch)
                }
            }
            .padding()

            Divider()

            if viewModel.useRawEditor {
                RawPlistEditorView(viewModel: viewModel)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        basicSection
                        Divider()
                        scheduleSection
                        Divider()
                        logsSection
                        Divider()
                        EnvironmentEditorView(variables: $viewModel.environmentVariables)
                    }
                    .padding()
                }
            }

            Divider()

            // Footer
            HStack {
                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(viewModel.isEditing ? "Save" : "Create") {
                    Task {
                        do {
                            try await viewModel.save()
                            onSave()
                        } catch {
                            viewModel.error = error.localizedDescription
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.isValid || viewModel.saving)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    // MARK: - Sections

    @ViewBuilder
    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic")
                .font(.headline)

            LabeledContent("Label") {
                TextField("com.example.myagent", text: $viewModel.label)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isEditing)
            }

            LabeledContent("Program") {
                TextField("/usr/bin/command", text: $viewModel.program)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledContent("Arguments") {
                TextEditor(text: $viewModel.programArguments)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 60)
                    .border(.tertiary)
            }

            HStack(spacing: 20) {
                Toggle("Run at Load", isOn: $viewModel.runAtLoad)
                Toggle("Keep Alive", isOn: $viewModel.keepAlive)
            }

            LabeledContent("Working Directory") {
                TextField("(optional)", text: $viewModel.workingDirectory)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)

            Picker("Type", selection: $viewModel.scheduleType) {
                ForEach(JobEditorViewModel.ScheduleType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            ScheduleEditorView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logging")
                .font(.headline)

            LabeledContent("Stdout Path") {
                TextField("(optional)", text: $viewModel.standardOutPath)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledContent("Stderr Path") {
                TextField("(optional)", text: $viewModel.standardErrorPath)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
