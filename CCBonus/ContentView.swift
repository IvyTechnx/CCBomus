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
        let isBonus = BonusTimeModel.isBonusTime(at: currentDate)
        let remaining = BonusTimeModel.timeUntilTransition(at: currentDate)
        let etTime = BonusTimeModel.currentETTimeString(at: currentDate)
        let jstTime = BonusTimeModel.currentJSTTimeString(at: currentDate)

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
                // Top thin accent line
                Rectangle()
                    .fill(isBonus ? SXColor.teal : SXColor.amber)
                    .frame(height: 2)

                // Header
                header(isBonus: isBonus)

                // Countdown
                countdown(isBonus: isBonus, remaining: remaining)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Clock
                AnalogClockView(currentDate: currentDate)
                    .frame(width: 210, height: 210)
                    .padding(.top, 12)

                // Time row
                HStack(spacing: 0) {
                    timeBlock(labelTop: "EASTERN", labelBottom: "STANDARD TIME", value: etTime)
                    Rectangle().fill(SXColor.border).frame(width: 1)
                    timeBlock(labelTop: "JAPAN", labelBottom: "STANDARD TIME", value: jstTime)
                }
                .frame(height: 52)
                .background(SXColor.panel)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(SXColor.border))
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Rate bar
                rateBar(isBonus: isBonus)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer(minLength: 0)

                // Footer
                footer()
            }
        }
        .frame(width: 340, height: 540)
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

    func header(isBonus: Bool) -> some View {
        HStack(alignment: .center) {
            Text("CLAUDE CODE")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SXColor.dim)
                .tracking(3)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(isBonus ? SXColor.teal : SXColor.amber)
                    .frame(width: 6, height: 6)
                    .opacity(pulse ? 1 : 0.3)

                Text(isBonus ? "BONUS ACTIVE" : "STANDBY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isBonus ? SXColor.teal : SXColor.amber)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Countdown

    func countdown(isBonus: Bool, remaining: (hours: Int, minutes: Int, seconds: Int)) -> some View {
        VStack(spacing: 8) {
            Text(isBonus ? "BONUS ENDS IN" : "BONUS STARTS IN")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(SXColor.dim)
                .tracking(2)

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

    // MARK: - Time Block

    func timeBlock(labelTop: String, labelBottom: String, value: String) -> some View {
        VStack(spacing: 3) {
            VStack(spacing: 0) {
                Text(labelTop)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(SXColor.dim)
                    .tracking(2)
                Text(labelBottom)
                    .font(.system(size: 7, weight: .regular))
                    .foregroundStyle(SXColor.dim.opacity(0.6))
                    .tracking(1.5)
            }
            Text(value)
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .foregroundStyle(SXColor.text)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
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
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.04))

                    // Fill
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
            Text("PEAK 21–03 JST (EDT)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(SXColor.dim.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Analog Clock (JST, SpaceX minimal)

struct AnalogClockView: View {
    let currentDate: Date

    var body: some View {
        let isBonus = BonusTimeModel.isBonusTime(at: currentDate)
        let isAM = BonusTimeModel.isAM(at: currentDate)
        let hourAngle = BonusTimeModel.hourHandAngle(at: currentDate)
        let minuteAngle = BonusTimeModel.minuteHandAngle(at: currentDate)
        let secondAngle = BonusTimeModel.secondHandAngle(at: currentDate)

        // Peak hours in JST (e.g. EDT: 21-3, EST: 22-4)
        let peak = BonusTimeModel.peakHoursJST(at: currentDate)
        let peakStart12 = peak.start % 12  // e.g. 9 (for 21:00)
        let peakEnd12 = peak.end % 12      // e.g. 3 (for 03:00)
        let peakStartDeg = Double(peakStart12) * 30.0  // clock degrees
        let peakEndDeg = Double(peakEnd12) * 30.0

        ZStack {
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let R = min(size.width, size.height) / 2 - 4

                // Outer ring
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: center.x - R, y: center.y - R,
                                           width: R * 2, height: R * 2)),
                    with: .color(.white.opacity(0.08)),
                    style: StrokeStyle(lineWidth: 1)
                )

                // Zone arcs (JST based)
                let arcR = R - 6

                // Peak arc (amber): peakStart → peakEnd (clockwise through 12)
                let peakArc = Path { p in
                    p.addArc(center: center, radius: arcR,
                             startAngle: .degrees(peakStartDeg - 90),
                             endAngle: .degrees(peakEndDeg - 90),
                             clockwise: false)
                }
                ctx.stroke(peakArc,
                          with: .color(SXColor.amber.opacity(0.25)),
                          style: StrokeStyle(lineWidth: 10, lineCap: .butt))

                // Bonus arc (teal): peakEnd → peakStart
                let bonusArc = Path { p in
                    p.addArc(center: center, radius: arcR,
                             startAngle: .degrees(peakEndDeg - 90),
                             endAngle: .degrees(peakStartDeg - 90),
                             clockwise: false)
                }
                ctx.stroke(bonusArc,
                          with: .color(SXColor.teal.opacity(0.15)),
                          style: StrokeStyle(lineWidth: 10, lineCap: .butt))

                // Zone labels
                // PEAK label midpoint
                let peakMidDeg: Double
                if peakStartDeg > peakEndDeg {
                    peakMidDeg = (peakStartDeg + peakEndDeg + 360) / 2
                } else {
                    peakMidDeg = (peakStartDeg + peakEndDeg) / 2
                }
                let peakLA = Angle.degrees(peakMidDeg - 90)
                ctx.draw(
                    ctx.resolve(Text("PEAK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SXColor.amber.opacity(0.9))),
                    at: CGPoint(x: center.x + arcR * CGFloat(cos(peakLA.radians)),
                                y: center.y + arcR * CGFloat(sin(peakLA.radians))),
                    anchor: .center
                )

                // BONUS label midpoint
                let bonusMidDeg: Double
                if peakEndDeg < peakStartDeg {
                    bonusMidDeg = (peakEndDeg + peakStartDeg) / 2
                } else {
                    bonusMidDeg = (peakEndDeg + peakStartDeg + 360) / 2
                }
                let bonusLA = Angle.degrees(bonusMidDeg - 90)
                ctx.draw(
                    ctx.resolve(Text("BONUS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SXColor.teal.opacity(0.9))),
                    at: CGPoint(x: center.x + arcR * CGFloat(cos(bonusLA.radians)),
                                y: center.y + arcR * CGFloat(sin(bonusLA.radians))),
                    anchor: .center
                )

                // Boundary time labels outside ring
                let boundR = R + 6
                // Peak start (e.g. 21:00)
                let psA = Angle.degrees(peakStartDeg - 90)
                ctx.draw(
                    ctx.resolve(Text("\(peak.start):00")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(SXColor.amber.opacity(0.8))),
                    at: CGPoint(x: center.x + boundR * CGFloat(cos(psA.radians)),
                                y: center.y + boundR * CGFloat(sin(psA.radians))),
                    anchor: .center
                )
                // Peak end (e.g. 3:00)
                let peA = Angle.degrees(peakEndDeg - 90)
                ctx.draw(
                    ctx.resolve(Text("\(peak.end):00")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(SXColor.teal.opacity(0.8))),
                    at: CGPoint(x: center.x + boundR * CGFloat(cos(peA.radians)),
                                y: center.y + boundR * CGFloat(sin(peA.radians))),
                    anchor: .center
                )

                // Hour markers
                for h in 1...12 {
                    let deg = Double(h) * 30.0 - 90.0
                    let cosA = CGFloat(cos(Angle.degrees(deg).radians))
                    let sinA = CGFloat(sin(Angle.degrees(deg).radians))

                    let isBound = (h == peakStart12 || h == peakEnd12)
                    let isQuarter = (h % 3 == 0)
                    let tickOut = R - 1
                    let tickLen: CGFloat = isBound ? 10 : (isQuarter ? 9 : 5)

                    let outer = CGPoint(x: center.x + tickOut * cosA, y: center.y + tickOut * sinA)
                    let inner = CGPoint(x: center.x + (tickOut - tickLen) * cosA,
                                        y: center.y + (tickOut - tickLen) * sinA)

                    var tick = Path()
                    tick.move(to: outer)
                    tick.addLine(to: inner)

                    if isBound {
                        ctx.stroke(tick, with: .color(.white.opacity(0.85)),
                                  style: StrokeStyle(lineWidth: 2))
                    } else {
                        ctx.stroke(tick, with: .color(.white.opacity(isQuarter ? 0.4 : 0.15)),
                                  style: StrokeStyle(lineWidth: isQuarter ? 1.5 : 0.8))
                    }

                    // Numbers (skip boundary positions - they have time labels)
                    if !isBound {
                        let numR = R - 20
                        let lp = CGPoint(x: center.x + numR * cosA, y: center.y + numR * sinA)
                        ctx.draw(
                            ctx.resolve(Text("\(h)")
                                .font(.system(size: 11, weight: .light))
                                .foregroundColor(.white.opacity(0.35))),
                            at: lp, anchor: .center
                        )
                    }
                }

                // Minute ticks
                for m in 0..<60 {
                    if m % 5 == 0 { continue }
                    let deg = Double(m) * 6.0 - 90.0
                    let cosA = CGFloat(cos(Angle.degrees(deg).radians))
                    let sinA = CGFloat(sin(Angle.degrees(deg).radians))
                    let o = R - 1
                    let outer = CGPoint(x: center.x + o * cosA, y: center.y + o * sinA)
                    let inner = CGPoint(x: center.x + (o - 2) * cosA,
                                        y: center.y + (o - 2) * sinA)
                    var t = Path()
                    t.move(to: outer)
                    t.addLine(to: inner)
                    ctx.stroke(t, with: .color(.white.opacity(0.06)),
                              style: StrokeStyle(lineWidth: 0.5))
                }

                // Hands
                drawHand(ctx: ctx, center: center, angle: hourAngle,
                         length: R * 0.48, width: 3.5, color: .white)
                drawHand(ctx: ctx, center: center, angle: minuteAngle,
                         length: R * 0.68, width: 2, color: .white.opacity(0.75))

                // Second hand
                let secRad = Angle.degrees(secondAngle - 90).radians
                let secEnd = CGPoint(x: center.x + R * 0.75 * CGFloat(cos(secRad)),
                                     y: center.y + R * 0.75 * CGFloat(sin(secRad)))
                let secTail = CGPoint(x: center.x - R * 0.12 * CGFloat(cos(secRad)),
                                      y: center.y - R * 0.12 * CGFloat(sin(secRad)))
                var secPath = Path()
                secPath.move(to: secTail)
                secPath.addLine(to: secEnd)
                ctx.stroke(secPath, with: .color(.red),
                          style: StrokeStyle(lineWidth: 1, lineCap: .round))

                // Center
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)),
                        with: .color(.red))
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - 1.5, y: center.y - 1.5, width: 3, height: 3)),
                        with: .color(.black))
            }

            // JST label top
            VStack(spacing: 1) {
                Text("JAPAN TIME")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(SXColor.dim)
                Text(isAM ? "AM" : "PM")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundStyle(SXColor.dim.opacity(0.6))
            }
            .offset(y: -55)
        }
    }

    func drawHand(ctx: GraphicsContext, center: CGPoint,
                  angle: Double, length: CGFloat, width: CGFloat, color: Color) {
        let rad = Angle.degrees(angle - 90).radians
        let end = CGPoint(x: center.x + length * CGFloat(cos(rad)),
                          y: center.y + length * CGFloat(sin(rad)))
        var p = Path()
        p.move(to: center)
        p.addLine(to: end)
        ctx.stroke(p, with: .color(color),
                  style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

#Preview {
    ContentView()
}
