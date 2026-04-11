import SwiftUI

struct EnvironmentEditorView: View {
    @Binding var variables: [(key: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Environment Variables")
                    .font(.headline)
                Spacer()
                Button {
                    variables.append((key: "", value: ""))
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            if variables.isEmpty {
                Text("No environment variables configured.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                    GridRow {
                        Text("Key")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text("Value")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text("")
                    }

                    ForEach(Array(variables.enumerated()), id: \.offset) { index, _ in
                        GridRow {
                            TextField("KEY", text: binding(for: index, keyPath: \.key))
                                .textFieldStyle(.roundedBorder)
                            TextField("value", text: binding(for: index, keyPath: \.value))
                                .textFieldStyle(.roundedBorder)
                            Button {
                                variables.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func binding(for index: Int, keyPath: WritableKeyPath<(key: String, value: String), String>) -> Binding<String> {
        Binding(
            get: { variables[index][keyPath: keyPath] },
            set: { variables[index][keyPath: keyPath] = $0 }
        )
    }
}
