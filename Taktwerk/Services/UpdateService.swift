import Foundation

struct AppUpdate: Sendable {
    let version: String
    let dmgURL: URL
    let releaseURL: URL
    let releaseNotes: String
}

actor UpdateService {
    static let shared = UpdateService()

    private let repoOwner = "olohmann"
    private let repoName = "Taktwerk"

    func checkForUpdate() async -> AppUpdate? {
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String,
                  let releaseURL = URL(string: htmlURL) else {
                return nil
            }

            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            guard Self.isNewer(remote: remoteVersion, current: currentVersion) else {
                return nil
            }

            let releaseNotes = json["body"] as? String ?? ""

            // Find DMG asset
            var dmgURL: URL?
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String,
                       name.hasSuffix(".dmg"),
                       let downloadURL = asset["browser_download_url"] as? String {
                        dmgURL = URL(string: downloadURL)
                        break
                    }
                }
            }

            guard let dmgURL else { return nil }

            return AppUpdate(
                version: remoteVersion,
                dmgURL: dmgURL,
                releaseURL: releaseURL,
                releaseNotes: releaseNotes
            )
        } catch {
            return nil
        }
    }

    /// Semantic version comparison: returns true if remote > current
    static func isNewer(remote: String, current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        let r = remoteParts + Array(repeating: 0, count: max(0, 3 - remoteParts.count))
        let c = currentParts + Array(repeating: 0, count: max(0, 3 - currentParts.count))

        for i in 0..<min(r.count, c.count) {
            if r[i] > c[i] { return true }
            if r[i] < c[i] { return false }
        }
        return false
    }

    /// Returns true if the given version should be shown (not skipped, or skipped version is older)
    static func shouldShowUpdate(version: String, skippedVersion: String?) -> Bool {
        guard let skipped = skippedVersion, !skipped.isEmpty else { return true }
        return isNewer(remote: version, current: skipped)
    }
}
