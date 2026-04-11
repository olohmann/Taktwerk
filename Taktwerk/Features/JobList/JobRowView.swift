import SwiftUI

struct JobRowView: View {
    let job: JobListEntry
    var tags: [TagDefinition]
    var tagDefinitions: [TagDefinition]
    var onStart: () -> Void
    var onStop: () -> Void
    var onRestart: () -> Void
    var onKickstart: () -> Void
    var onDelete: () -> Void
    var onRevealInFinder: () -> Void
    var onToggleTag: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(job.label)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StatusBadge(status: job.status)
                    SourceBadge(source: job.source)
                    if let pid = job.pid {
                        Text("PID \(pid)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    ForEach(tags) { tag in
                        TagBadge(tag: tag)
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            if job.source.isEditable {
                Button("Start") { onStart() }
                Button("Stop") { onStop() }
                Button("Restart") { onRestart() }
                Button("Test Run (Kickstart)") { onKickstart() }
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
                Divider()
            }

            if !tagDefinitions.isEmpty {
                Menu("Tags") {
                    ForEach(tagDefinitions) { tag in
                        Button {
                            onToggleTag(tag.id)
                        } label: {
                            HStack {
                                Text(tag.name)
                                if tags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                Divider()
            }

            Button("Reveal in Finder") { onRevealInFinder() }
        }
    }
}

struct TagBadge: View {
    let tag: TagDefinition

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(tag.color.opacity(0.2), in: Capsule())
            .foregroundStyle(tag.color)
    }
}
