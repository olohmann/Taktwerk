import SwiftUI

struct PlistConfigView: View {
    let config: PlistConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                configRow("Label", config.label)

                if let program = config.program {
                    configRow("Program", program)
                }

                if let args = config.programArguments, !args.isEmpty {
                    configRow("Arguments", args.joined(separator: " "))
                }

                if let runAtLoad = config.runAtLoad {
                    configRow("Run at Load", runAtLoad ? "Yes" : "No")
                }

                if let keepAlive = config.keepAlive {
                    configRow("Keep Alive", keepAlive ? "Yes" : "No")
                }

                if let disabled = config.disabled {
                    configRow("Disabled", disabled ? "Yes" : "No")
                }

                if let wakeSystem = config.wakeSystem {
                    configRow("Wake System", wakeSystem ? "Yes" : "No")
                }

                if let wd = config.workingDirectory {
                    configRow("Working Dir", wd)
                }

                if let stdout = config.standardOutPath {
                    configRow("Stdout", stdout)
                }

                if let stderr = config.standardErrorPath {
                    configRow("Stderr", stderr)
                }
            }

            if let env = config.environmentVariables, !env.isEmpty {
                Text("Environment Variables")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 4) {
                    ForEach(env.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        GridRow {
                            Text(key)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(value)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func configRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}
