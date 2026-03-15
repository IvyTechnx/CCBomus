import Foundation

struct BonusTimeModel {
    // Peak (no bonus) = PT 5:00-11:00 on weekdays only
    // Weekends = all day bonus
    static let peakStartHourPT = 5
    static let peakEndHourPT = 11

    private static var ptTimeZone: TimeZone {
        TimeZone(identifier: "America/Los_Angeles")!
    }

    private static var jstTimeZone: TimeZone {
        TimeZone(identifier: "Asia/Tokyo")!
    }

    // MARK: - PT Time

    static func currentPTHour(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone
        return cal.component(.hour, from: date)
    }

    static func currentPTMinute(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone
        return cal.component(.minute, from: date)
    }

    static func currentPTTimeString(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = ptTimeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - JST Time

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

    static func currentJSTTimeString(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = jstTimeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - Weekend / Day

    /// Whether the current time falls on a weekend in PT
    static func isWeekend(at date: Date = Date()) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone
        let weekday = cal.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }

    /// Current day abbreviation in PT (e.g. "MON", "SAT")
    static func currentPTDayName(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = ptTimeZone
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date).uppercased()
    }

    /// Current day abbreviation in JST (e.g. "MON", "SUN")
    static func currentJSTDayName(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = jstTimeZone
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date).uppercased()
    }

    // MARK: - Promotion

    /// Promotion period: March 13-27, 2026 (PT)
    static func isPromotionActive(at date: Date = Date()) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone
        let start = cal.date(from: DateComponents(year: 2026, month: 3, day: 13, hour: 0, minute: 0))!
        let end = cal.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 23, minute: 59, second: 59))!
        return date >= start && date <= end
    }

    /// Days remaining in promotion
    static func promotionDaysRemaining(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone
        let end = cal.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 23, minute: 59, second: 59))!
        let days = cal.dateComponents([.day], from: date, to: end).day ?? 0
        return max(0, days)
    }

    // MARK: - Bonus Time

    /// Whether the current time is bonus (off-peak) time
    static func isBonusTime(at date: Date = Date()) -> Bool {
        guard isPromotionActive(at: date) else { return false }
        if isWeekend(at: date) { return true }
        let hour = currentPTHour(at: date)
        return hour < peakStartHourPT || hour >= peakEndHourPT
    }

    // MARK: - Transitions

    /// Time remaining until the next bonus/peak transition
    static func timeUntilTransition(at date: Date = Date()) -> (hours: Int, minutes: Int, seconds: Int) {
        let target: Date
        if isBonusTime(at: date) {
            target = nextPeakStart(after: date)
        } else {
            target = nextBonusStart(after: date)
        }
        let remaining = max(0, Int(target.timeIntervalSince(date)))
        return (hours: remaining / 3600,
                minutes: (remaining % 3600) / 60,
                seconds: remaining % 60)
    }

    /// Next time peak begins (next weekday at 5:00 AM PT)
    private static func nextPeakStart(after date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone

        let hour = cal.component(.hour, from: date)
        let weekday = cal.component(.weekday, from: date)
        let isWeekday = weekday >= 2 && weekday <= 6

        // Today is a weekday and peak hasn't started yet
        if isWeekday && hour < peakStartHourPT {
            var comps = cal.dateComponents([.year, .month, .day], from: date)
            comps.hour = peakStartHourPT; comps.minute = 0; comps.second = 0
            return cal.date(from: comps)!
        }

        // Find the next weekday
        var nextDate = cal.startOfDay(for: date)
        for _ in 1...7 {
            nextDate = cal.date(byAdding: .day, value: 1, to: nextDate)!
            let wd = cal.component(.weekday, from: nextDate)
            if wd >= 2 && wd <= 6 {
                var comps = cal.dateComponents([.year, .month, .day], from: nextDate)
                comps.hour = peakStartHourPT; comps.minute = 0; comps.second = 0
                return cal.date(from: comps)!
            }
        }
        return date // fallback, should not reach
    }

    /// Next time bonus begins (today at 11:00 AM PT)
    private static func nextBonusStart(after date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ptTimeZone
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = peakEndHourPT; comps.minute = 0; comps.second = 0
        return cal.date(from: comps)!
    }

    // MARK: - Progress

    /// Progress through the current period (0.0 to 1.0)
    static func periodProgress(at date: Date = Date()) -> Double {
        if !isBonusTime(at: date) {
            // Peak: PT 5:00-11:00 (6 hours = 360 min)
            let hour = currentPTHour(at: date)
            let minute = currentPTMinute(at: date)
            let elapsed = Double((hour - peakStartHourPT) * 60 + minute)
            return elapsed / (6.0 * 60.0)
        } else {
            return 1.0
        }
    }

    // MARK: - JST Peak Hours

    /// Peak hours converted to JST (dynamically handles PDT/PST)
    static func peakHoursJST(at date: Date = Date()) -> (start: Int, end: Int) {
        let ptOffset = ptTimeZone.secondsFromGMT(for: date)
        let jstOffset = jstTimeZone.secondsFromGMT(for: date)
        let diffHours = (jstOffset - ptOffset) / 3600
        let start = (peakStartHourPT + diffHours) % 24
        let end = (peakEndHourPT + diffHours) % 24
        return (start: start, end: end)
    }

    // MARK: - Clock Hands (JST)

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

    static func isAM(at date: Date = Date()) -> Bool {
        return currentJSTHour(at: date) < 12
    }
}
