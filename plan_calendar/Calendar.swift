import SwiftUI

// MARK: - Week View (fixed with scrollable events)
struct WeekView: View {
    @Binding var weekStart: Date
    var events: [CalendarEvent]
    var onWeekChange: (Date, Date) -> Void = { _,_ in }
    
    var body: some View {
        GeometryReader { geo in
            let calendar = Calendar.current
            // Calculate Sunday start of the week
            let localStart = calendar.startOfDay(for: weekStart)
            let weekdayIndex = calendar.component(.weekday, from: localStart) // Sunday = 1
            let sundayStart = calendar.date(
                byAdding: .day,
                value: -(weekdayIndex - 1),
                to: localStart
            )!
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Button {
                        weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .frame(width: geo.size.width / 8)
                    
                    Text(
                        "\(DateFormatter.headerFormatter.string(from: sundayStart)) - " +
                        "\(DateFormatter.headerFormatter.string(from: calendar.date(byAdding: .day, value: 6, to: sundayStart)!))"
                    )
                    .font(.subheadline)
                    .frame(width: geo.size.width * 6 / 8)
                    
                    Button {
                        weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .frame(width: geo.size.width / 8)
                }
                .padding(.vertical, 6)
                Divider()
                
                // Weekday names & dates (Sunday → Saturday)
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: geo.size.width / 8)
                    
                    ForEach(0..<7) { idx in
                        let date = calendar.date(byAdding: .day, value: idx, to: sundayStart)!
                        VStack(spacing: 2) {
                            Text(DateFormatter.weekdayShortFormatter.string(from: date))
                                .font(.caption2)
                            Text(DateFormatter.dayFormatter.string(from: date))
                                .font(.caption2)
                        }
                        .frame(width: geo.size.width / 8, height: 30)
                        .background(
                            // Highlight today using Circle
                            Group {
                                if calendar.isDate(date, inSameDayAs: Date()) {
                                    Circle()
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: 30, height: 30)
                                        .offset(y: 15 - 30/2)
                                } else {
                                    Color.clear
                                }
                            }                        )
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
                                    let dayDate = calendar.date(byAdding: .day, value: idx, to: sundayStart)!
                                    HourEventView(hour: hour, day: dayDate, events: events)
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
        .onAppear { notify() }
        .onChange(of: weekStart) { _ in notify() }
    }
    
    private func notify() {
        let calendar = Calendar.current
        let localStart = calendar.startOfDay(for: weekStart)
        let weekdayIndex = calendar.component(.weekday, from: localStart)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekdayIndex - 1), to: localStart)!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        onWeekChange(startOfWeek, endOfWeek)
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

// MARK: - Hour Event View with horizontal scrolling
struct HourEventView: View {
    let hour: Int
    let day: Date
    let events: [CalendarEvent]
    var body: some View {
        let dayEvents = events.filter { ev in
            Calendar.current.isDate(ev.start, inSameDayAs: day) &&
            Calendar.current.component(.hour, from: ev.start) == hour
        }
        if dayEvents.isEmpty {
            Color.clear
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(dayEvents) { ev in
                        EventBlockView(event: ev)
                            .frame(width: 100, height: 50)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Calendar Cell (highlight today)
struct CalendarCell: View {
    let date: Date?
    let events: [CalendarEvent]
    
    var body: some View {
        VStack(spacing: 4) {
            if let d = date {
                ZStack {
                    // 🟣 Today highlight circle
                    if Calendar.current.isDate(d, inSameDayAs: Date()) {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 32, height: 32)
                    }
                    
                    // Date number button
                    Button(action: {
                        print("tap on Calendar Cell of \(DateFormatter.fullDateFormatter.string(from: d))")
                    }) {
                        Text(DateFormatter.dayFormatter.string(from: d))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            } else {
                Text("")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(height: 32)
            }
            
            Spacer()
            
            // Events
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


// MARK: - Day View (fixed with scrollable events)
struct DayView: View {
    @Binding var date: Date
    var events: [CalendarEvent]
    var onDayChange: (Date, Date) -> Void = { _,_ in }
    
    private var startOfDay: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private var endOfDay: Date {
        let start = startOfDay
        return Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: start
        )!.addingTimeInterval(-1)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    date = Calendar.current.date(
                        byAdding: .day,
                        value: -1,
                        to: date
                    )!
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(DateFormatter.weekdayDateFormatter.string(from: date))
                Spacer()
                Button {
                    date = Calendar.current.date(
                        byAdding: .day,
                        value: 1,
                        to: date
                    )!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.vertical, 6)
            Divider()
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(0..<24) { hour in
                        HStack(spacing: 0) {
                            Text(String(format: "%02d", hour))
                                .font(.caption2)
                                .frame(width: 40)
                            Divider()
                            HourEventView(
                                hour: hour,
                                day: date,
                                events: events
                            )
                            .frame(height: 60)
                            .padding(.horizontal, 4)
                        }
                        Divider()
                    }
                }
            }
        }
        .onAppear { onDayChange(startOfDay, endOfDay) }
        .onChange(of: date) { _ in onDayChange(startOfDay, endOfDay) }
    }
}

// MARK: - Month View with start/end dates
struct MonthView: View {
    @Binding var month: Date
    var events: [CalendarEvent]
    var onMonthChange: (Date, Date) -> Void = { _,_ in }
    
    private var calendar: Calendar { Calendar.current }
    
    private var startOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
    }
    
    private var endOfMonth: Date {
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        return calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth)!
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Month header with start/end dates
            HStack {
                Button {
                    month = calendar.date(byAdding: .month, value: -1, to: month)!
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                VStack {
                    Text(DateFormatter.monthYearFormatter.string(from: month))
                        .font(.headline)
                    Text("\(DateFormatter.headerFormatter.string(from: startOfMonth)) - \(DateFormatter.headerFormatter.string(from: endOfMonth))")
                        .font(.subheadline)
                }
                Spacer()
                Button {
                    month = calendar.date(byAdding: .month, value: 1, to: month)!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            Divider()
            
            // Weekday labels
            HStack(spacing: 0) {
                ForEach(0..<7) { idx in
                    Text(DateFormatter.weekdayShortFormatter.string(
                        from: calendar.date(
                            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: month)
                        )!.addingTimeInterval(Double(idx) * 86400)
                    ))
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            Divider()
            
            // Month grid
            let grid = DateHelper.makeMonthGrid(for: month)
            let rows = stride(from: 0, to: grid.count, by: 7).map {
                Array(grid[$0 ..< min($0 + 7, grid.count)])
            }
            
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7) { col in
                            let dateOpt = rows[rowIndex][col]
                            CalendarCell(
                                date: dateOpt,
                                events: events.filter { ev in
                                    if let d = dateOpt {
                                        return calendar.isDate(ev.start, inSameDayAs: d)
                                    }
                                    return false
                                }
                            )
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            
                            if col < 6 {
                                Divider().frame(width: 1)
                            }
                        }
                    }
                    Divider()
                }
            }
        }
        .onAppear { onMonthChange(startOfMonth, endOfMonth) }
        .onChange(of: month) { _ in onMonthChange(startOfMonth, endOfMonth) }
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
    static let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt
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
                DayView(date: $currentDate, events: events) { startDate, endDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.timeZone = Calendar.current.timeZone
//                    let s = DateFormatter.headerFormatter.string(from: startDate)
//                    let e = DateFormatter.headerFormatter.string(from: endDate)
                    let s = formatter.string(from: startDate)
                    let e   = formatter.string(from: endDate)
                    print("📆 Day start: \(s), end: \(e)")
                }
            case .week:
                WeekView(weekStart: $weekStart, events: events) { startDate, endDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.timeZone = Calendar.current.timeZone
                    
                    let startText = formatter.string(from: startDate)
                    let endText   = formatter.string(from: endDate)
                    print("📆 Week start: \(startText), end: \(endText)")
                }
                
            case .month:
                MonthView(month: $monthDate, events: events) { startDate, endDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    formatter.timeZone = Calendar.current.timeZone
                    //                    let startText = DateFormatter.headerFormatter.string(from: startDate)
                    //                    let endText   = DateFormatter.headerFormatter.string(from: endDate)
                    let startText = formatter.string(from: startDate)
                    let endText   = formatter.string(from: endDate)
                    print("📆 Month start: \(startText), end: \(endText)")
                }
            }
        }
    }
}

// MARK: - Sample Events
//let sampleEvents: [CalendarEvent] = {
//    let cal = Calendar.current
//    var arr: [CalendarEvent] = []
//    if let s1 = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
//       let e1 = cal.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) {
//        arr.append(.init(start: s1, end: e1, label: "Meeting", color: .orange))
//    }
//    if let s2 = cal.date(bySettingHour: 14, minute: 15, second: 10, of: Date()),
//       let e2 = cal.date(bySettingHour: 15, minute: 0, second: 10, of: Date()) {
//        arr.append(.init(start: s2, end: e2, label: "test", color: .black))
//    }
//    if let s3 = cal.date(bySettingHour: 13, minute: 15, second: 30, of: Date()),
//       let e3 = cal.date(bySettingHour: 12, minute: 10, second: 20, of: Date()) {
//        arr.append(.init(start: s3, end: e3, label: "Bamawl", color: .red))
//    }
//    if let s4 = cal.date(bySettingHour: 13, minute: 15, second: 30, of: Date()),
//       let e4 = cal.date(bySettingHour: 12, minute: 10, second: 20, of: Date()) {
//        arr.append(.init(start: s4, end: e4, label: "Same Time with Bamawl", color: .green))
//    }
//    return arr
//}()

// MARK: - Sample Events (expanded to 50 items with duplicates & varied colors)
let sampleEvents: [CalendarEvent] = {
    let cal = Calendar.current
    let year = cal.component(.year, from: Date())
    guard let yesterday = cal.date(byAdding: .day, value: -1, to: Date()),
          let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()),
          let june25 = cal.date(from: DateComponents(year: year, month: 6, day: 25)),
          let sept24 = cal.date(from: DateComponents(year: year, month: 9, day: 24))
    else { return [] }
    let baseDates: [(String, Date)] = [
        ("Yesterday", yesterday),
        ("Today", Date()),
        ("Tomorrow", tomorrow),
        ("June 25", june25),
        ("Sept 24", sept24)
    ]
    var arr: [CalendarEvent] = []
    var idx = 1
    
    // For each base date, add 4 events
    for (label, dateBase) in baseDates {
        let times: [(Int, Int)] = [(1,3), (1,2), (9,11), (14,15)]
        for (startH, endH) in times {
            if let s = cal.date(bySettingHour: startH, minute: 0, second: 0, of: dateBase),
               let e = cal.date(bySettingHour: endH, minute: 0, second: 0, of: dateBase) {
                arr.append(.init(
                    start: s,
                    end: e,
                    label: "\(label) Event \(idx)",
                    color: EventColor.allCases[idx % EventColor.allCases.count]
                ))
                idx += 1
            }
        }
    }
    
    // Duplicate existing 16 items with different colors
    let original = arr
    for (i, ev) in original.enumerated() {
        var newEv = ev
        newEv.color = EventColor.allCases[(i + 1) % EventColor.allCases.count]
        newEv.id = UUID()
        arr.append(newEv)
    }
    
    // If still less than 50, add extra events
    while arr.count < 50 {
        let dateBase = Date()
        let hour = arr.count % 24
        if let s = cal.date(bySettingHour: hour, minute: 0, second: 0, of: dateBase),
           let e = cal.date(bySettingHour: (hour + 1) % 24, minute: 0, second: 0, of: dateBase) {
            arr.append(.init(
                start: s,
                end: e,
                label: "Extra Event \(arr.count + 1)",
                color: EventColor.allCases[(arr.count + 1) % EventColor.allCases.count]
            ))
        }
    }
    
    return arr
}()

struct ContentView: View {
    var body: some View {
        CalendarView(events: sampleEvents)
    }
}
