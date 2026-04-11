import SwiftUI

struct LogViewerView: View {
    let config: PlistConfig

    @State private var selectedTab: LogTab = .stdout
    @State private var logContent = ""
    @State private var modifiedAt: Date?
    @State private var error: String?

    enum LogTab: String, CaseIterable {
        case stdout = "Stdout"
        case stderr = "Stderr"
    }

    private var currentPath: String? {
        switch selectedTab {
        case .stdout: config.standardOutPath
        case .stderr: config.standardErrorPath
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Logs")
                    .font(.headline)

                Spacer()

                Picker("Log", selection: $selectedTab) {
                    if config.standardOutPath != nil {
                        Text("Stdout").tag(LogTab.stdout)
                    }
                    if config.standardErrorPath != nil {
                        Text("Stderr").tag(LogTab.stderr)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Button {
                    Task { await loadLog() }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                if let path = currentPath {
                    Menu {
                        Button("Clear Log") {
                            Task { await clearLog(path: path) }
                        }
                        Button("Open in Editor") {
                            Task { await LogService.shared.openInEditor(path: path) }
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let modifiedAt {
                Text("Last modified: \(modifiedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let path = currentPath {
                Text(path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                ScrollView {
                    Text(logContent.isEmpty ? "(empty)" : logContent)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
                .padding(8)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Text("No log path configured for \(selectedTab.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .task(id: selectedTab) {
            await loadLog()
        }
        .errorAlert($error)
    }

    private func loadLog() async {
        guard let path = currentPath else { return }
        do {
            let result = try await LogService.shared.readLog(at: path, tailLines: 200)
            logContent = result.content
            modifiedAt = result.modifiedAt
        } catch {
            logContent = ""
            modifiedAt = nil
            // Don't show error for missing log files — that's expected
        }
    }

    private func clearLog(path: String) async {
        do {
            try await LogService.shared.clearLog(at: path)
            await loadLog()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
