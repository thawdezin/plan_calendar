import SwiftUI

// MARK: - Week View (fixed)
struct WeekView: View {
    @Binding var weekStart: Date
    var events: [CalendarEvent]
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Button { weekStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart)! } label: { Image(systemName: "chevron.left") }
                        .frame(width: geo.size.width / 8)
                    Text("\(DateFormatter.headerFormatter.string(from: weekStart)) - \(DateFormatter.headerFormatter.string(from: Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!))")
                        .font(.subheadline)
                        .frame(width: geo.size.width * 6 / 8)
                    Button { weekStart = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)! } label: { Image(systemName: "chevron.right") }
                        .frame(width: geo.size.width / 8)
                }
                .padding(.vertical, 6)
                Divider()

                // Weekday names and dates
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: geo.size.width / 8)
                    ForEach(0..<7) { idx in
                        let d = Calendar.current.date(byAdding: .day, value: idx, to: weekStart)!
                        VStack(spacing: 2) {
                            Text(DateFormatter.weekdayShortFormatter.string(from: d))
                                .font(.caption2)
                            Text(DateFormatter.dayFormatter.string(from: d))
                                .font(.caption2)
                        }
                        .frame(width: geo.size.width / 8, height: 30)
                    }
                }
                .padding(.vertical, 8)
                Divider()

                // Hours grid with day dividers
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(0..<24) { hour in
                            HStack(spacing: 0) {
                                Text(String(format: "%02d", hour))
                                    .font(.caption2)
                                    .frame(width: geo.size.width / 8)
                                Divider()
                                ForEach(0..<7) { idx in
                                    let d = Calendar.current.date(byAdding: .day, value: idx, to: weekStart)!
                                    HourEventView(hour: hour, day: d, events: events)
                                        .frame(width: geo.size.width / 8, height: 60)
                                    if idx < 6 { Divider().frame(width: 1) }
                                }
                            }
                            Divider()
                        }
                    }
                }
            }
        }
    }
}



struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// MARK: - Event Data Model (with duration & label)
struct CalendarEvent: Identifiable {
    var id = UUID()
    let start: Date
    let end: Date
    let label: String
    var color: EventColor
    
    // Helpers
    var timeRangeText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: start))–\(fmt.string(from: end))"
    }
}

enum EventColor: CaseIterable {
    case green, yellow, orange, red, black
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        case .black: return .black
        }
    }
}

// MARK: - Event Block View (tap prints event)
struct EventBlockView: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(event.color.color)
                .frame(width: 4)
            VStack(spacing: 2) {
                Text(event.timeRangeText)
                    .font(.caption2).bold()
                Spacer(minLength: 0)
                Text(event.label)
                    .font(.caption)
                Spacer(minLength: 0)
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(event.color.color, lineWidth: 1)
                .background(Color.white.cornerRadius(8))
        )
        .onTapGesture {
            print("tap on event \(event.label) from \(event.timeRangeText)")
        }
    }
}

// MARK: - Hour Event View (fixed)
struct HourEventView: View {
    let hour: Int
    let day: Date
    let events: [CalendarEvent]
    var body: some View {
        ZStack {
            // Filter events by day and hour
            let dayEvents = events.filter { ev in
                Calendar.current.isDate(ev.start, inSameDayAs: day) &&
                Calendar.current.component(.hour, from: ev.start) == hour
            }
            ForEach(dayEvents) { ev in
                EventBlockView(event: ev)
                    .frame(height: 50)
                    .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Calendar Cell
struct CalendarCell: View {
    let date: Date?
    let events: [CalendarEvent]
    var body: some View {
        VStack(spacing: 4) {
            // Date number tap area
            if let d = date {
                Button(action: {
                    print("tap on Calendar Cell of \(DateFormatter.fullDateFormatter.string(from: d))")
                }) {
                    Text(DateFormatter.dayFormatter.string(from: d))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            } else {
                Text("")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            Spacer()
            // Horizontal scrollable events
            if !events.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(events) { ev in
                            EventBlockView(event: ev)
                                .frame(width: 120, height: 50)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: 36)
            } else {
                Spacer()
            }
        }
        .padding(4)
    }
}

// MARK: - Day View
struct DayView: View {
    @Binding var date: Date
    var events: [CalendarEvent]
    var body: some View {
        VStack {
            HStack {
                Button { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(DateFormatter.weekdayDateFormatter.string(from: date))
                Spacer()
                Button { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! } label: { Image(systemName: "chevron.right") }
            }.padding()
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<24) { hour in
                        HStack(spacing: 0) {
                            Text(String(format: "%02d", hour))
                                .frame(width: 40)
                            Divider()
                            ZStack { Rectangle().fill(Color.clear)
                                HourEventView(hour: hour, day: date, events: events)
                            }
                        }
                        .frame(height: 60)
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Month View
struct MonthView: View {
    @Binding var month: Date
    var events: [CalendarEvent]
    var body: some View {
        VStack {
            HStack {
                Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month)! } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(DateFormatter.monthYearFormatter.string(from: month))
                Spacer()
                Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month)! } label: { Image(systemName: "chevron.right") }
            }
            .padding()
            Divider()
            let gridItems = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach(DateHelper.makeMonthGrid(for: month), id: \ .self) { date in
                    CalendarCell(
                        date: date,
                        events: events.filter { d in
                            if let d0 = date {
                                return Calendar.current.isDate(d.start, inSameDayAs: d0)
                            }
                            return false
                        }
                    )
                    .frame(height: 80)
                }
            }
            .padding()
        }
    }
}

// MARK: - Helpers & Formatters
struct DateHelper {
    static func makeMonthGrid(for date: Date) -> [Date?] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: date) else { return [] }
        let startWeekday = cal.component(.weekday, from: interval.start) - 1
        let days = cal.range(of: .day, in: .month, for: date)!
        var grid: [Date?] = Array(repeating: nil, count: startWeekday)
        for d in days {
            grid.append(cal.date(bySetting: .day, value: d, of: date))
        }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "dd"; return f }()
    static let weekdayFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE"; return f }()
    static let weekdayDateFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE, MMM d, yyyy"; return f }()
    static let monthYearFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f }()
    static let simpleFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d MMM"; return f }()
    static let fullDateFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "dd-MM-yyyy HH:mm"; return f }()
    static let weekdayShortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()
}


// MARK: - Main Calendar View
enum CalendarMode { case day, week, month }

struct CalendarView: View {
    @State private var mode: CalendarMode = .month
    @State private var currentDate: Date = Date()
    @State private var weekStart: Date = Calendar.current.startOfDay(for: Date())
    @State private var monthDate: Date = Date()
    var events: [CalendarEvent]
    var body: some View {
        VStack {
            Picker(selection: $mode, label: Text("Mode")) {
                Text("Day").tag(CalendarMode.day)
                Text("Week").tag(CalendarMode.week)
                Text("Month").tag(CalendarMode.month)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            switch mode {
            case .day:
                DayView(date: $currentDate, events: events)
            case .week:
                WeekView(weekStart: $weekStart, events: events)
            case .month:
                MonthView(month: $monthDate, events: events)
            }
        }
    }
}

// MARK: - Sample Events
let sampleEvents: [CalendarEvent] = {
    let cal = Calendar.current
    var arr: [CalendarEvent] = []
    if let s1 = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
       let e1 = cal.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) {
        arr.append(.init(start: s1, end: e1, label: "Meeting", color: .orange))
    }
    if let s2 = cal.date(bySettingHour: 14, minute: 15, second: 10, of: Date()),
       let e2 = cal.date(bySettingHour: 15, minute: 0, second: 10, of: Date()) {
        arr.append(.init(start: s2, end: e2, label: "test", color: .black))
    }
    if let s3 = cal.date(bySettingHour: 13, minute: 15, second: 30, of: Date()),
       let e3 = cal.date(bySettingHour: 12, minute: 10, second: 20, of: Date()) {
        arr.append(.init(start: s3, end: e3, label: "Bamawl", color: .red))
    }
    if let s4 = cal.date(bySettingHour: 13, minute: 15, second: 30, of: Date()),
       let e4 = cal.date(bySettingHour: 12, minute: 10, second: 20, of: Date()) {
        arr.append(.init(start: s4, end: e4, label: "Same Time with Bamawl", color: .green))
    }
    return arr
}()


struct ContentView: View {
    var body: some View {
        CalendarView(events: sampleEvents)
    }
}
