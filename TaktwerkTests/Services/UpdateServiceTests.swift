import Testing
@testable import Taktwerk

struct UpdateServiceTests {

    // MARK: - Semver Comparison

    @Test("Newer major version detected")
    func newerMajor() {
        #expect(UpdateService.isNewer(remote: "2.0.0", current: "1.0.0"))
    }

    @Test("Newer minor version detected")
    func newerMinor() {
        #expect(UpdateService.isNewer(remote: "1.2.0", current: "1.1.0"))
    }

    @Test("Newer patch version detected")
    func newerPatch() {
        #expect(UpdateService.isNewer(remote: "1.0.1", current: "1.0.0"))
    }

    @Test("Same version is not newer")
    func sameVersion() {
        #expect(!UpdateService.isNewer(remote: "1.0.0", current: "1.0.0"))
    }

    @Test("Older version is not newer")
    func olderVersion() {
        #expect(!UpdateService.isNewer(remote: "1.0.0", current: "2.0.0"))
    }

    @Test("Partial version strings padded correctly")
    func partialVersion() {
        #expect(UpdateService.isNewer(remote: "1.1", current: "1.0.0"))
        #expect(!UpdateService.isNewer(remote: "1.0", current: "1.0.0"))
    }

    // MARK: - Skip Version Logic

    @Test("Shows update when no version is skipped")
    func showUpdateNoSkip() {
        #expect(UpdateService.shouldShowUpdate(version: "2.0.0", skippedVersion: nil))
        #expect(UpdateService.shouldShowUpdate(version: "2.0.0", skippedVersion: ""))
    }

    @Test("Hides update when skipped version matches")
    func hideUpdateSkipped() {
        #expect(!UpdateService.shouldShowUpdate(version: "2.0.0", skippedVersion: "2.0.0"))
    }

    @Test("Shows update when newer than skipped version")
    func showUpdateNewerThanSkipped() {
        #expect(UpdateService.shouldShowUpdate(version: "2.1.0", skippedVersion: "2.0.0"))
    }

    @Test("Hides update when older than skipped version")
    func hideUpdateOlderThanSkipped() {
        #expect(!UpdateService.shouldShowUpdate(version: "1.9.0", skippedVersion: "2.0.0"))
    }
}
