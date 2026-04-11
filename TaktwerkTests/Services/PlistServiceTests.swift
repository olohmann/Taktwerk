@testable import Taktwerk
import Testing
import Foundation

@Suite("PlistService Tests")
struct PlistServiceTests {

    @Test("Parse simple plist XML")
    func parseSimplePlist() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.example.test</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/true</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """
        let tempFile = createTempPlist(xml)
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let config = try await PlistService.shared.parsePlist(at: tempFile)
        #expect(config.label == "com.example.test")
        #expect(config.programArguments == ["/usr/bin/true"])
        #expect(config.runAtLoad == true)
        #expect(config.keepAlive == nil)
    }

    @Test("Parse plist with calendar interval")
    func parseCalendarInterval() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.example.cron</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/true</string>
            </array>
            <key>StartCalendarInterval</key>
            <dict>
                <key>Hour</key>
                <integer>3</integer>
                <key>Minute</key>
                <integer>30</integer>
            </dict>
        </dict>
        </plist>
        """
        let tempFile = createTempPlist(xml)
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let config = try await PlistService.shared.parsePlist(at: tempFile)
        let intervals = try #require(config.startCalendarInterval)
        #expect(intervals.count == 1)
        #expect(intervals[0].hour == 3)
        #expect(intervals[0].minute == 30)
    }

    @Test("Write and read plist round-trip")
    func writeAndReadRoundTrip() async throws {
        let config = PlistConfig(
            label: "com.example.roundtrip",
            program: "/usr/bin/echo",
            programArguments: ["/usr/bin/echo", "hello"],
            runAtLoad: true,
            keepAlive: false,
            startInterval: 300,
            standardOutPath: "/tmp/test.log",
            workingDirectory: "/tmp",
            environmentVariables: ["FOO": "bar"],
            rawXML: ""
        )

        let tempFile = NSTemporaryDirectory() + "test-roundtrip-\(UUID().uuidString).plist"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        try await PlistService.shared.writePlist(to: tempFile, config: config)
        let parsed = try await PlistService.shared.parsePlist(at: tempFile)

        #expect(parsed.label == "com.example.roundtrip")
        #expect(parsed.program == "/usr/bin/echo")
        #expect(parsed.runAtLoad == true)
        #expect(parsed.keepAlive == false)
        #expect(parsed.startInterval == 300)
        #expect(parsed.standardOutPath == "/tmp/test.log")
        #expect(parsed.workingDirectory == "/tmp")
        #expect(parsed.environmentVariables == ["FOO": "bar"])
    }

    @Test("Write raw plist validates XML")
    func writeRawPlistValidation() async {
        let invalidXML = "this is not valid plist"
        let tempFile = NSTemporaryDirectory() + "test-invalid-\(UUID().uuidString).plist"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        do {
            try await PlistService.shared.writeRawPlist(to: tempFile, xml: invalidXML)
            Issue.record("Expected error for invalid XML")
        } catch {
            // Expected
        }
    }

    // MARK: - Helpers

    private func createTempPlist(_ xml: String) -> String {
        let path = NSTemporaryDirectory() + "test-\(UUID().uuidString).plist"
        try! xml.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}
