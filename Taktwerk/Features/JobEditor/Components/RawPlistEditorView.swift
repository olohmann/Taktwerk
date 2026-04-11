import SwiftUI

struct RawPlistEditorView: View {
    @Bindable var viewModel: JobEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with character count and validate button
            HStack {
                Text("Raw Plist XML")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.rawXML.count) characters")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button {
                    Task { await viewModel.validateWithPlutil() }
                } label: {
                    Label("Validate (plutil)", systemImage: "checkmark.shield")
                        .font(.caption)
                }
                .disabled(viewModel.validatingPlutil)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Validation warning
            if let xmlError = viewModel.xmlValidationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(xmlError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            // plutil output
            if let plutilOutput = viewModel.plutilOutput {
                HStack(spacing: 4) {
                    Text(plutilOutput)
                        .font(.caption)
                        .foregroundStyle(plutilOutput.hasPrefix("✅") ? .green : .red)
                    Spacer()
                    Button {
                        viewModel.plutilOutput = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            TextEditor(text: $viewModel.rawXML)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .onChange(of: viewModel.rawXML) {
                    viewModel.validateXML()
                }
        }
    }
}
