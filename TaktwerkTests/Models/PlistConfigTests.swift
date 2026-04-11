@testable import Taktwerk
import Testing
import Foundation

@Suite("CalendarInterval Tests")
struct CalendarIntervalTests {

    @Test("Next fire date for daily schedule")
    func nextFireDateDaily() {
        let interval = CalendarInterval(minute: 30, hour: 3)
        let next = interval.nextFireDate()
        #expect(next != nil)
    }

    @Test("Summary formatting")
    func summaryFormatting() {
        let interval = CalendarInterval(minute: 30, hour: 3, weekday: 1)
        let summary = interval.summary
        #expect(summary.contains("Hour: 3"))
        #expect(summary.contains("Minute: 30"))
        #expect(summary.contains("Monday"))
    }

    @Test("Interval formatting")
    func intervalFormatting() {
        #expect(UInt64(30).formattedInterval == "30s")
        #expect(UInt64(90).formattedInterval == "1m 30s")
        #expect(UInt64(3661).formattedInterval == "1h 1m")
    }
}
