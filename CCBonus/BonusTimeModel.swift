import Foundation

struct BonusTimeModel {
    // Off-peak (bonus) = outside 8:00-14:00 ET
    // Peak (no bonus)  = 8:00-14:00 ET
    static let peakStartHourET = 8
    static let peakEndHourET = 14

    private static var etTimeZone: TimeZone {
        TimeZone(identifier: "America/New_York")!
    }

    /// Current hour in Eastern Time (0-23)
    static func currentETHour(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etTimeZone
        return cal.component(.hour, from: date)
    }

    /// Current minute in Eastern Time
    static func currentETMinute(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etTimeZone
        return cal.component(.minute, from: date)
    }

    // Promotion period: March 13-27, 2026 (ends 11:59 PM PT on March 27)
    static func isPromotionActive(at date: Date = Date()) -> Bool {
        let ptZone = TimeZone(identifier: "America/Los_Angeles")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptZone
        let start = cal.date(from: DateComponents(year: 2026, month: 3, day: 13, hour: 0, minute: 0))!
        let end = cal.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 23, minute: 59, second: 59))!
        return date >= start && date <= end
    }

    /// Days remaining in promotion
    static func promotionDaysRemaining(at date: Date = Date()) -> Int {
        let ptZone = TimeZone(identifier: "America/Los_Angeles")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptZone
        let end = cal.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 23, minute: 59, second: 59))!
        let days = cal.dateComponents([.day], from: date, to: end).day ?? 0
        return max(0, days)
    }

    /// Whether the current time is bonus (off-peak) time
    static func isBonusTime(at date: Date = Date()) -> Bool {
        guard isPromotionActive(at: date) else { return false }
        let hour = currentETHour(at: date)
        return hour < peakStartHourET || hour >= peakEndHourET
    }

    /// Progress through the current period (0.0 to 1.0)
    /// During peak: how far through the 6-hour peak window
    /// During bonus: how far through the 18-hour bonus window
    static func periodProgress(at date: Date = Date()) -> Double {
        let hour = currentETHour(at: date)
        let minute = currentETMinute(at: date)
        let totalMinutes = Double(hour * 60 + minute)

        if isBonusTime(at: date) {
            // Bonus is 14:00 - 08:00 next day (18 hours = 1080 min)
            let bonusDuration = 18.0 * 60.0
            if hour >= peakEndHourET {
                // 14:00 ~ 23:59
                let elapsed = totalMinutes - Double(peakEndHourET * 60)
                return elapsed / bonusDuration
            } else {
                // 00:00 ~ 07:59
                let elapsed = totalMinutes + Double((24 - peakEndHourET) * 60)
                return elapsed / bonusDuration
            }
        } else {
            // Peak is 08:00 - 14:00 (6 hours = 360 min)
            let peakDuration = 6.0 * 60.0
            let elapsed = totalMinutes - Double(peakStartHourET * 60)
            return elapsed / peakDuration
        }
    }

    /// Time remaining until the next transition
    static func timeUntilTransition(at date: Date = Date()) -> (hours: Int, minutes: Int, seconds: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etTimeZone
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let second = cal.component(.second, from: date)

        let targetHour: Int
        if isBonusTime(at: date) {
            targetHour = peakStartHourET
        } else {
            targetHour = peakEndHourET
        }

        var remainingSeconds = (targetHour * 3600) - (hour * 3600 + minute * 60 + second)
        if remainingSeconds <= 0 {
            remainingSeconds += 24 * 3600
        }

        let h = remainingSeconds / 3600
        let m = (remainingSeconds % 3600) / 60
        let s = remainingSeconds % 60
        return (hours: h, minutes: m, seconds: s)
    }

    /// Format current ET time
    static func currentETTimeString(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = etTimeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    /// Format current JST time
    static func currentJSTTimeString(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private static var jstTimeZone: TimeZone {
        TimeZone(identifier: "Asia/Tokyo")!
    }

    static func currentJSTHour(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = jstTimeZone
        return cal.component(.hour, from: date)
    }

    static func currentJSTMinute(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = jstTimeZone
        return cal.component(.minute, from: date)
    }

    static func currentJSTSecond(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = jstTimeZone
        return cal.component(.second, from: date)
    }

    /// Peak start/end in JST (dynamically computed from ET offset)
    static func peakHoursJST(at date: Date = Date()) -> (start: Int, end: Int) {
        // Compute ET→JST offset dynamically (handles EDT/EST)
        let etOffset = etTimeZone.secondsFromGMT(for: date)
        let jstOffset = jstTimeZone.secondsFromGMT(for: date)
        let diffHours = (jstOffset - etOffset) / 3600
        let start = (peakStartHourET + diffHours) % 24
        let end = (peakEndHourET + diffHours) % 24
        return (start: start, end: end)
    }

    /// Clock hand angles in JST
    static func hourHandAngle(at date: Date = Date()) -> Double {
        let hour = currentJSTHour(at: date) % 12
        let minute = currentJSTMinute(at: date)
        return Double(hour * 30) + Double(minute) * 0.5
    }

    static func minuteHandAngle(at date: Date = Date()) -> Double {
        let minute = currentJSTMinute(at: date)
        let second = currentJSTSecond(at: date)
        return Double(minute * 6) + Double(second) * 0.1
    }

    static func secondHandAngle(at date: Date = Date()) -> Double {
        let second = currentJSTSecond(at: date)
        return Double(second * 6)
    }

    /// Whether it's AM in JST
    static func isAM(at date: Date = Date()) -> Bool {
        return currentJSTHour(at: date) < 12
    }
}
