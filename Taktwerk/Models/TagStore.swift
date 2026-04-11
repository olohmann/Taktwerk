import Foundation
import Observation
import SwiftUI

struct TagDefinition: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var colorHex: String

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    init(id: String = UUID().uuidString, name: String, colorHex: String = "007AFF") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

@Observable
@MainActor
final class TagStore {
    static let shared = TagStore()

    var tagDefinitions: [TagDefinition] = [] {
        didSet { persistDefinitions() }
    }

    // job label → [tag ID]
    var tagAssignments: [String: [String]] = [:] {
        didSet { persistAssignments() }
    }

    private let definitionsKey = "tagDefinitions"
    private let assignmentsKey = "tagAssignments"

    init() {
        loadDefinitions()
        loadAssignments()
        migrateNameBasedAssignments()
        seedDefaultTagsIfNeeded()
    }

    private func seedDefaultTagsIfNeeded() {
        guard tagDefinitions.isEmpty,
              !UserDefaults.standard.bool(forKey: "tagDefaultsSeeded") else { return }
        tagDefinitions = [
            TagDefinition(name: "Tag-1", colorHex: "FF3B30"),
            TagDefinition(name: "Tag-2", colorHex: "AF52DE"),
        ]
        UserDefaults.standard.set(true, forKey: "tagDefaultsSeeded")
    }

    /// Migrate old name-based assignments to ID-based
    private func migrateNameBasedAssignments() {
        var migrated = false
        for (label, tagRefs) in tagAssignments {
            let newRefs = tagRefs.map { ref -> String in
                // If ref matches a tag ID, keep it
                if tagDefinitions.contains(where: { $0.id == ref }) { return ref }
                // If ref matches a tag name, convert to ID
                if let def = tagDefinitions.first(where: { $0.name == ref }) {
                    migrated = true
                    return def.id
                }
                return ref
            }
            if newRefs != tagRefs {
                tagAssignments[label] = newRefs
            }
        }
        if migrated { persistAssignments() }
    }

    // MARK: - Tag Definitions CRUD

    func addTag(_ name: String, colorHex: String = "007AFF") {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !tagDefinitions.contains(where: { $0.name == trimmed }) else { return }
        tagDefinitions.append(TagDefinition(name: trimmed, colorHex: colorHex))
    }

    func removeTag(id: String) {
        tagDefinitions.removeAll { $0.id == id }
        for (label, tags) in tagAssignments {
            tagAssignments[label] = tags.filter { $0 != id }
            if tagAssignments[label]?.isEmpty == true {
                tagAssignments.removeValue(forKey: label)
            }
        }
    }

    func renameTag(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Ensure no duplicate names
        guard !tagDefinitions.contains(where: { $0.id != id && $0.name == trimmed }) else { return }
        if let index = tagDefinitions.firstIndex(where: { $0.id == id }) {
            tagDefinitions[index].name = trimmed
        }
    }

    func updateTagColor(id: String, colorHex: String) {
        if let index = tagDefinitions.firstIndex(where: { $0.id == id }) {
            tagDefinitions[index].colorHex = colorHex
        }
    }

    // MARK: - Tag Assignments (by tag ID)

    func tags(for label: String) -> [TagDefinition] {
        let ids = tagAssignments[label] ?? []
        return ids.compactMap { id in tagDefinitions.first { $0.id == id } }
    }

    func hasTag(id tagID: String, on label: String) -> Bool {
        tagAssignments[label]?.contains(tagID) == true
    }

    func toggleTag(id tagID: String, on label: String) {
        var current = tagAssignments[label] ?? []
        if current.contains(tagID) {
            current.removeAll { $0 == tagID }
        } else {
            current.append(tagID)
        }
        tagAssignments[label] = current.isEmpty ? nil : current
    }

    func assignTag(id tagID: String, to label: String) {
        var current = tagAssignments[label] ?? []
        guard !current.contains(tagID) else { return }
        current.append(tagID)
        tagAssignments[label] = current
    }

    func removeTag(id tagID: String, from label: String) {
        var current = tagAssignments[label] ?? []
        current.removeAll { $0 == tagID }
        tagAssignments[label] = current.isEmpty ? nil : current
    }

    // MARK: - Lookup

    func definition(for id: String) -> TagDefinition? {
        tagDefinitions.first { $0.id == id }
    }

    // MARK: - Persistence

    private func persistDefinitions() {
        if let data = try? JSONEncoder().encode(tagDefinitions) {
            UserDefaults.standard.set(data, forKey: definitionsKey)
        }
    }

    private func persistAssignments() {
        if let data = try? JSONEncoder().encode(tagAssignments) {
            UserDefaults.standard.set(data, forKey: assignmentsKey)
        }
    }

    private func loadDefinitions() {
        guard let data = UserDefaults.standard.data(forKey: definitionsKey),
              let defs = try? JSONDecoder().decode([TagDefinition].self, from: data)
        else { return }
        tagDefinitions = defs
    }

    private func loadAssignments() {
        guard let data = UserDefaults.standard.data(forKey: assignmentsKey),
              let assignments = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return }
        tagAssignments = assignments
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        guard hexStr.count == 6, let rgb = UInt64(hexStr, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "007AFF" }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
