import SwiftUI

// MARK: - SpaceX Design System

enum SXColor {
    static let bg = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let panel = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let border = Color.white.opacity(0.06)
    static let blue = Color(red: 0.25, green: 0.65, blue: 1.0)
    static let teal = Color(red: 0.75, green: 0.82, blue: 0.88)
    static let amber = Color(red: 1.0, green: 0.7, blue: 0.15)
    static let dim = Color.white.opacity(0.55)
    static let text = Color.white.opacity(0.88)
}

struct ContentView: View {
    @State private var currentDate = Date()
    @State private var pulse: Bool = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let promoActive = BonusTimeModel.isPromotionActive(at: currentDate)
        let isBonus = BonusTimeModel.isBonusTime(at: currentDate)
        let remaining = BonusTimeModel.timeUntilTransition(at: currentDate)
        let daysLeft = BonusTimeModel.promotionDaysRemaining(at: currentDate)
        let ptTime = BonusTimeModel.currentPTTimeString(at: currentDate)
        let jstTime = BonusTimeModel.currentJSTTimeString(at: currentDate)
        let isWeekend = BonusTimeModel.isWeekend(at: currentDate)
        let dayName = BonusTimeModel.currentJSTDayName(at: currentDate)
        let ptDayName = BonusTimeModel.currentPTDayName(at: currentDate)

        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.06),
                    Color(red: 0.0, green: 0.0, blue: 0.0),
                    Color(red: 0.02, green: 0.02, blue: 0.04)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top accent line
                Rectangle()
                    .fill(isBonus ? SXColor.teal : SXColor.amber)
                    .frame(height: 2)

                // Header
                header(isBonus: isBonus, promoActive: promoActive, isWeekend: isWeekend)

                // Promo period
                promoBar(active: promoActive, daysLeft: daysLeft)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Countdown
                if promoActive {
                    countdown(isBonus: isBonus, isWeekend: isWeekend, remaining: remaining)
                        .padding(.top, 14)
                        .padding(.horizontal, 20)
                } else {
                    promoExpired()
                        .padding(.top, 14)
                        .padding(.horizontal, 20)
                }

                // 24-hour Timeline
                TimelineView(currentDate: currentDate)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                // Clock panel
                let peak = BonusTimeModel.peakHoursJST(at: currentDate)
                clockPanel(
                    jstTime: jstTime, ptTime: ptTime,
                    jstPeakStart: String(format: "%02d:00", peak.start),
                    jstPeakEnd: String(format: "%02d:00", peak.end),
                    isWeekend: isWeekend, dayName: dayName, ptDayName: ptDayName
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Rate bar
                rateBar(isBonus: isBonus)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // Weekly limit note
                if isBonus {
                    Text("OFF-PEAK USAGE DOES NOT COUNT TOWARD WEEKLY LIMITS")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(SXColor.teal.opacity(0.8))
                        .tracking(1)
                        .padding(.top, 6)
                }

                Spacer(minLength: 0)

                // Footer
                footer()
            }
        }
        .frame(width: 380, height: 520)
        .onReceive(timer) { date in
            currentDate = date
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: - Header

    func header(isBonus: Bool, promoActive: Bool, isWeekend: Bool) -> some View {
        HStack(alignment: .center) {
            Text("CLAUDE CODE")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SXColor.dim)
                .tracking(3)

            Spacer()

            if promoActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isBonus ? SXColor.teal : SXColor.amber)
                        .frame(width: 6, height: 6)
                        .opacity(pulse ? 1 : 0.3)

                    Text(isBonus ? (isWeekend ? "WEEKEND 2X" : "BONUS ACTIVE") : "STANDBY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isBonus ? SXColor.teal : SXColor.amber)
                }
            } else {
                Text("PROMO ENDED")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Promo Bar

    func promoBar(active: Bool, daysLeft: Int) -> some View {
        HStack {
            Text("PROMOTION")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(SXColor.dim)
                .tracking(1.5)
            Spacer()
            if active {
                Text("MAR 13–27, 2026 ・ \(daysLeft)D LEFT")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(SXColor.text)
            } else {
                Text("ENDED MAR 27, 2026")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(SXColor.panel)
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(SXColor.border))
        )
    }

    // MARK: - Promo Expired

    func promoExpired() -> some View {
        VStack(spacing: 4) {
            Text("PROMOTION HAS ENDED")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.red.opacity(0.7))
                .tracking(2)
            Text("Usage limits have returned to standard levels")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(SXColor.dim)
        }
    }

    // MARK: - Countdown

    func countdown(isBonus: Bool, isWeekend: Bool, remaining: (hours: Int, minutes: Int, seconds: Int)) -> some View {
        VStack(spacing: 8) {
            if isBonus {
                Text(isWeekend ? "WEEKEND BONUS ENDS IN" : "BONUS ENDS IN")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SXColor.dim)
                    .tracking(2)
            } else {
                Text("BONUS STARTS IN")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SXColor.dim)
                    .tracking(2)
            }

            HStack(spacing: 0) {
                cDigit(remaining.hours, unit: "H")
                cSep
                cDigit(remaining.minutes, unit: "M")
                cSep
                cDigit(remaining.seconds, unit: "S")
            }
        }
    }

    func cDigit(_ v: Int, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(String(format: "%02d", v))
                .font(.system(size: 38, weight: .light, design: .monospaced))
                .foregroundStyle(SXColor.text)
                .monospacedDigit()
            Text(unit)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(SXColor.dim)
                .offset(y: -2)
        }
        .frame(minWidth: 70)
    }

    var cSep: some View {
        Text(":")
            .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
            .foregroundStyle(SXColor.dim.opacity(0.8))
            .frame(width: 12)
            .offset(y: -3)
    }

    // MARK: - Clock Panel

    func clockPanel(jstTime: String, ptTime: String,
                    jstPeakStart: String, jstPeakEnd: String,
                    isWeekend: Bool, dayName: String, ptDayName: String) -> some View {
        VStack(spacing: 12) {
            // JST (primary)
            VStack(spacing: 4) {
                Text("JAPAN STANDARD TIME")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(SXColor.dim)
                    .tracking(2)
                Text(jstTime)
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .foregroundStyle(SXColor.text)
                    .monospacedDigit()
                if isWeekend {
                    HStack(spacing: 4) {
                        Text(dayName)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(SXColor.teal.opacity(0.8))
                        Text("ALL DAY BONUS")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(SXColor.teal)
                    }
                } else {
                    HStack(spacing: 4) {
                        Text("PEAK")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(SXColor.amber.opacity(0.8))
                        Text("\(jstPeakStart) – \(jstPeakEnd)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(SXColor.amber)
                    }
                }
            }

            Rectangle().fill(SXColor.border).frame(height: 1)
                .padding(.horizontal, 20)

            // PT (secondary)
            VStack(spacing: 3) {
                Text("PACIFIC TIME")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(SXColor.dim.opacity(0.7))
                    .tracking(1.5)
                HStack(spacing: 6) {
                    Text(ptTime)
                        .font(.system(size: 20, weight: .light, design: .monospaced))
                        .foregroundStyle(SXColor.text.opacity(0.7))
                        .monospacedDigit()
                    Text(ptDayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isWeekend ? SXColor.teal.opacity(0.7) : SXColor.dim.opacity(0.5))
                }
                if isWeekend {
                    Text("WEEKEND — NO PEAK")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(SXColor.teal.opacity(0.6))
                } else {
                    HStack(spacing: 4) {
                        Text("PEAK")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(SXColor.amber.opacity(0.6))
                        Text("05:00 – 11:00")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(SXColor.amber.opacity(0.6))
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(SXColor.panel)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(SXColor.border))
        )
    }

    // MARK: - Rate Bar

    func rateBar(isBonus: Bool) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("RATE LIMIT")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(SXColor.dim)
                    .tracking(2)
                Spacer()
                Text(isBonus ? "2X" : "1X")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isBonus ? SXColor.teal : SXColor.amber)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: isBonus
                                    ? [SXColor.teal.opacity(0.7), SXColor.teal]
                                    : [SXColor.amber.opacity(0.5), SXColor.amber.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (isBonus ? 1.0 : 0.5))
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Footer

    func footer() -> some View {
        HStack {
            Text("BONUS TIME MONITOR")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(SXColor.dim.opacity(0.8))
                .tracking(2)
            Spacer()
            Text("PEAK 05–11 PT (WEEKDAYS)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(SXColor.dim.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - 24-Hour Horizontal Timeline (JST)

struct TimelineView: View {
    let currentDate: Date

    private var jstHour: Int { BonusTimeModel.currentJSTHour(at: currentDate) }
    private var jstMin: Int { BonusTimeModel.currentJSTMinute(at: currentDate) }
    private var jstSec: Int { BonusTimeModel.currentJSTSecond(at: currentDate) }
    private var peak: (start: Int, end: Int) { BonusTimeModel.peakHoursJST(at: currentDate) }
    private var isBonus: Bool { BonusTimeModel.isBonusTime(at: currentDate) }
    private var isWeekend: Bool { BonusTimeModel.isWeekend(at: currentDate) }
    private var nowFrac: Double {
        (Double(jstHour) * 3600 + Double(jstMin) * 60 + Double(jstSec)) / 86400.0
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.bottom, 8)
            timelineCanvas
                .frame(height: 50)
        }
    }

    var headerRow: some View {
        HStack {
            Text("JAPAN STANDARD TIME — 24H")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(SXColor.dim)
                .tracking(1.5)
            Spacer()
            if isWeekend {
                Text("2X WEEKEND")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(SXColor.teal)
            } else {
                Text(isBonus ? "2X BONUS" : "1X PEAK")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(isBonus ? SXColor.teal : SXColor.amber)
            }
        }
    }

    var timelineCanvas: some View {
        Canvas { ctx, size in
            let w = size.width
            let h: CGFloat = 20.0
            let barY: CGFloat = 14.0
            let now = CGFloat(nowFrac)

            if isWeekend {
                // Weekend: entire bar is bonus
                let barRect = CGRect(x: 0, y: barY, width: w, height: h)
                ctx.fill(
                    Path(roundedRect: barRect, cornerRadius: 4),
                    with: .color(SXColor.teal.opacity(0.3))
                )

                let bonusText = ctx.resolve(Text("ALL DAY BONUS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(SXColor.teal))
                ctx.draw(bonusText, at: CGPoint(x: w / 2, y: barY + h / 2), anchor: .center)
            } else {
                // Weekday: show peak/bonus zones
                let peakStartFrac = CGFloat(peak.start) / 24.0
                let peakEndFrac = CGFloat(peak.end) / 24.0

                // Bonus background
                let barRect = CGRect(x: 0, y: barY, width: w, height: h)
                ctx.fill(
                    Path(roundedRect: barRect, cornerRadius: 4),
                    with: .color(SXColor.teal.opacity(0.2))
                )

                // Peak zones (amber)
                if peak.start > peak.end {
                    // Wraps around midnight: peak from start→24 and 0→end
                    let leftRect = CGRect(x: 0, y: barY, width: w * peakEndFrac, height: h)
                    ctx.fill(Path(leftRect), with: .color(SXColor.amber.opacity(0.35)))
                    let rightRect = CGRect(x: w * peakStartFrac, y: barY,
                                           width: w * (1 - peakStartFrac), height: h)
                    ctx.fill(Path(rightRect), with: .color(SXColor.amber.opacity(0.35)))
                } else {
                    let peakRect = CGRect(x: w * peakStartFrac, y: barY,
                                          width: w * (peakEndFrac - peakStartFrac), height: h)
                    ctx.fill(Path(peakRect), with: .color(SXColor.amber.opacity(0.35)))
                }

                // Boundary lines
                var psLine = Path()
                psLine.move(to: CGPoint(x: w * peakStartFrac, y: barY - 2))
                psLine.addLine(to: CGPoint(x: w * peakStartFrac, y: barY + h + 2))
                ctx.stroke(psLine, with: .color(SXColor.amber.opacity(0.5)),
                          style: StrokeStyle(lineWidth: 1))

                var peLine = Path()
                peLine.move(to: CGPoint(x: w * peakEndFrac, y: barY - 2))
                peLine.addLine(to: CGPoint(x: w * peakEndFrac, y: barY + h + 2))
                ctx.stroke(peLine, with: .color(SXColor.amber.opacity(0.5)),
                          style: StrokeStyle(lineWidth: 1))

                // Zone labels
                let bonusCX: CGFloat = peak.start > peak.end
                    ? w * (peakEndFrac + peakStartFrac) / 2
                    : w * ((peakStartFrac + peakEndFrac + 1) / 2).truncatingRemainder(dividingBy: 1)
                let bonusText = ctx.resolve(Text("BONUS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(SXColor.teal))
                ctx.draw(bonusText, at: CGPoint(x: bonusCX, y: barY + h / 2), anchor: .center)

                let peakCX: CGFloat
                if peak.start > peak.end {
                    let span = (1 - peakStartFrac) + peakEndFrac
                    peakCX = ((peakStartFrac + span / 2).truncatingRemainder(dividingBy: 1)) * w
                } else {
                    peakCX = w * (peakStartFrac + peakEndFrac) / 2
                }
                let peakText = ctx.resolve(Text("PEAK")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(SXColor.amber))
                ctx.draw(peakText, at: CGPoint(x: peakCX, y: barY + h / 2), anchor: .center)
            }

            // Hour labels
            let keyHours = [0, 3, 6, 9, 12, 15, 18, 21]
            for hr in keyHours {
                let x = w * CGFloat(hr) / 24.0
                let isBound = !isWeekend && (hr == peak.start || hr == peak.end)
                let label = ctx.resolve(Text("\(hr)")
                    .font(.system(size: 8, weight: isBound ? .bold : .medium, design: .monospaced))
                    .foregroundColor(isBound ? .white.opacity(0.85) : .white.opacity(0.35)))
                ctx.draw(label, at: CGPoint(x: x, y: barY + h + 10), anchor: .center)
            }

            // NOW indicator
            var nowLine = Path()
            nowLine.move(to: CGPoint(x: w * now, y: barY - 4))
            nowLine.addLine(to: CGPoint(x: w * now, y: barY + h + 4))
            ctx.stroke(nowLine, with: .color(.white),
                      style: StrokeStyle(lineWidth: 2, lineCap: .round))

            // NOW time label
            let timeStr = String(format: "%02d:%02d", jstHour, jstMin)
            let timeLabel = ctx.resolve(Text(timeStr)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white))
            let labelX = min(max(w * now, 20), w - 20)
            ctx.draw(timeLabel, at: CGPoint(x: labelX, y: 4), anchor: .center)
        }
    }
}

#Preview {
    ContentView()
}
