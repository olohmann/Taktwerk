import Foundation

extension CalendarInterval {
    func nextFireDate(after date: Date = .now) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        if let month { components.month = Int(month) }
        if let day { components.day = Int(day) }
        if let weekday { components.weekday = Int(weekday) + 1 } // launchd uses 0=Sunday, DateComponents uses 1=Sunday
        if let hour { components.hour = Int(hour) }
        if let minute { components.minute = Int(minute) }

        return calendar.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTime
        )
    }
}

extension UInt64 {
    var formattedInterval: String {
        let seconds = self
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m \(seconds % 60)s" }
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        return "\(hours)h \(mins)m"
    }
}
