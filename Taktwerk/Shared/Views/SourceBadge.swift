import SwiftUI

struct SourceBadge: View {
    let source: JobSource

    var body: some View {
        Text(source.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch source {
        case .userAgent: .blue
        case .systemAgent: .purple
        case .systemDaemon: .orange
        }
    }
}
