import SwiftUI

struct StatusBadge: View {
    let status: JobStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var color: Color {
        switch status {
        case .running: .green
        case .loaded: .orange
        case .unloaded: .gray
        case .unknown: .red
        }
    }
}
