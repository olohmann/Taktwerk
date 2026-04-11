@testable import Taktwerk
import Testing

@Suite("LaunchctlService Tests")
struct LaunchctlServiceTests {

    @Test("Parse launchctl list output with running and stopped services")
    func parseListOutputBasic() {
        let output = """
        PID\tStatus\tLabel
        1234\t0\tcom.example.running
        -\t78\tcom.example.stopped
        """
        let result = LaunchctlService.parseListOutput(output)
        #expect(result.count == 2)
        #expect(result[0].label == "com.example.running")
        #expect(result[0].pid == 1234)
        #expect(result[0].lastExitCode == 0)
        #expect(result[1].label == "com.example.stopped")
        #expect(result[1].pid == nil)
        #expect(result[1].lastExitCode == 78)
    }

    @Test("Parse empty launchctl list output")
    func parseListOutputEmpty() {
        let output = "PID\tStatus\tLabel\n"
        let result = LaunchctlService.parseListOutput(output)
        #expect(result.isEmpty)
    }

    @Test("Parse launchctl list output with malformed lines")
    func parseListOutputMalformed() {
        let output = """
        PID\tStatus\tLabel
        bad line
        1234\t0\tcom.example.test
        """
        let result = LaunchctlService.parseListOutput(output)
        #expect(result.count == 1)
        #expect(result[0].label == "com.example.test")
    }
}
