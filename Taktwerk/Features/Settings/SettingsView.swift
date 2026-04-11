import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            TagsSettingsTab()
                .tabItem {
                    Label("Tags", systemImage: "tag")
                }
        }
        .frame(width: 480, height: 480)
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @AppStorage("defaultSourceFilter") private var defaultSourceFilter: String = SourceFilter.all.rawValue
    @AppStorage("defaultTagFilter") private var defaultTagFilter: String = ""
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Int = 60
    @AppStorage("logTailLines") private var logTailLines: Int = 1000
    private let tagStore = TagStore.shared

    private let refreshOptions: [(String, Int)] = [
        ("Off", 0),
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300),
    ]

    private let tailOptions: [(String, Int)] = [
        ("200 lines", 200),
        ("500 lines", 500),
        ("1,000 lines", 1000),
        ("2,000 lines", 2000),
        ("5,000 lines", 5000),
    ]

    var body: some View {
        Form {
            Section("Startup Defaults") {
                Picker("Default Source Filter", selection: $defaultSourceFilter) {
                    ForEach(SourceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("Default Tag Filter", selection: $defaultTagFilter) {
                    Text("None (show all)").tag("")
                    if !tagStore.tagDefinitions.isEmpty {
                        Divider()
                        ForEach(tagStore.tagDefinitions) { tag in
                            Label(tag.name, systemImage: "tag.fill")
                                .foregroundStyle(tag.color)
                                .tag(tag.id)
                        }
                    }
                }
            }

            Section("Auto-Refresh") {
                Picker("Refresh interval", selection: $autoRefreshInterval) {
                    ForEach(refreshOptions, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
            }

            Section("Logs") {
                Picker("Log tail length", selection: $logTailLines) {
                    ForEach(tailOptions, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Tags Settings

struct TagsSettingsTab: View {
    private let tagStore = TagStore.shared
    @State private var newTagName = ""
    @State private var newTagColorHex = "007AFF"

    private let presetColors: [(String, Color)] = [
        ("007AFF", .blue),
        ("34C759", .green),
        ("FF3B30", .red),
        ("FF9500", .orange),
        ("AF52DE", .purple),
        ("FF2D55", .pink),
        ("5AC8FA", .cyan),
        ("FFCC00", .yellow),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add new tag
            HStack(spacing: 10) {
                TextField("New tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                    .onSubmit {
                        guard !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        tagStore.addTag(newTagName, colorHex: newTagColorHex)
                        newTagName = ""
                    }

                // Inline color presets for new tag
                HStack(spacing: 5) {
                    ForEach(presetColors, id: \.0) { (hex, color) in
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                            .overlay {
                                if newTagColorHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .contentShape(Circle())
                            .onTapGesture {
                                newTagColorHex = hex
                            }
                    }
                }

                Button("Add") {
                    tagStore.addTag(newTagName, colorHex: newTagColorHex)
                    newTagName = ""
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Divider()

            if tagStore.tagDefinitions.isEmpty {
                Text("No tags defined yet. Create tags above to organize your agents.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            } else {
                List {
                    ForEach(tagStore.tagDefinitions) { tag in
                        TagSettingsRow(tag: tag, presetColors: presetColors, tagStore: tagStore)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Tag Settings Row

struct TagSettingsRow: View {
    let tag: TagDefinition
    let presetColors: [(String, Color)]
    let tagStore: TagStore

    @State private var isEditing = false
    @State private var editName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isEditing {
                    TextField("Tag name", text: $editName, onCommit: {
                        tagStore.renameTag(id: tag.id, newName: editName)
                        isEditing = false
                    })
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)

                    Button("Done") {
                        tagStore.renameTag(id: tag.id, newName: editName)
                        isEditing = false
                    }
                    .font(.caption)

                    Button("Cancel") {
                        isEditing = false
                    }
                    .font(.caption)
                } else {
                    TagBadge(tag: tag)

                    Button {
                        editName = tag.name
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button(role: .destructive) {
                    tagStore.removeTag(id: tag.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                ForEach(presetColors, id: \.0) { (hex, color) in
                    Circle()
                        .fill(color)
                        .frame(width: 18, height: 18)
                        .overlay {
                            if tag.colorHex.uppercased() == hex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            tagStore.updateTagColor(id: tag.id, colorHex: hex)
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
