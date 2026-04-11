import SwiftUI

struct FilterChip: View {
    let label: String
    let icon: String
    let color: Color
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
        .onTapGesture { onRemove() }
    }
}
