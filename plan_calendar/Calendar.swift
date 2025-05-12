import SwiftUI

// MARK: - Event Data Model (with duration & label)
struct CalendarEvent: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let label: String
    let color: EventColor
    
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

// MARK: - Event Block View
struct EventBlockView: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 0) {
            // Left colored bar
            Rectangle()
                .fill(event.color.color)
                .frame(width: 4)
            
            // Content
            VStack(spacing: 2) {
                Text(event.timeRangeText)
                    .font(.caption2)
                    .bold()
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
    }
}

struct HourEventView: View {
    let hour: Int
    let day: Date
    let events: [CalendarEvent]
    
    var body: some View {
        ZStack {
            ForEach(events) { ev in
                // လိုချင်တဲ့ start/end နှစ်ခုရှိတဲ့ event ကို filter
                let evStart = Calendar.current.component(.hour, from: ev.start)
                if evStart == hour {
                    EventBlockView(event: ev)
                        .frame(height: 50) // cell height ထည့်ပေး
                        .padding(.vertical, 4)
                }
            }
        }
    }
}


// MARK: - Calendar Cell
struct CalendarCell: View {
    let date: Date?
    let events: [CalendarEvent]
    let isCurrentMonth: Bool
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                VStack(spacing: 2) {
                    Text(date.map { DateFormatter.dayFormatter.string(from: $0) } ?? "")
                        .font(.caption)
                        .foregroundColor(isCurrentMonth ? .primary : .secondary)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(events.prefix(3)) { ev in
                            Circle()
                                .fill(ev.color.color)
                                .frame(width: geo.size.width / 8, height: geo.size.width / 8)
                        }
                        if events.count > 3 {
                            Text("+\(events.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let d = date {
                print("tap on Calendar Cell of \(DateFormatter.fullDateFormatter.string(from: d))")
            }
        }
    }
}

// MARK: - Day View
struct DayView: View {
    @Binding var date: Date
    var events: [CalendarEvent]
    var body: some View {
        VStack {
            HStack {
                Button(action: { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(DateFormatter.weekdayDateFormatter.string(from: date))
                Spacer()
                Button(action: { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<24) { hour in
                        HStack {
                            Text(String(format: "%02d", hour))
                                .frame(width: 40)
                            Divider()
                            ZStack {
                                Rectangle().fill(Color.clear)
                                HourEventView(hour: hour, day: date, events: events)
                            }
                        }
                        .frame(height: 60)
                    }
                }
            }
        }
    }
}

// MARK: - Week View
struct WeekView: View {
    @Binding var weekStart: Date
    var events: [CalendarEvent]
    var body: some View {
        VStack {
            HStack {
                Button(action: { weekStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart)! }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
                Text("\(DateFormatter.simpleFormatter.string(from: weekStart)) - \(DateFormatter.simpleFormatter.string(from: end))")
                Spacer()
                Button(action: { weekStart = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)! }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            Divider()
            ScrollView([.vertical, .horizontal]) {
                HStack(spacing: 0) {
                    VStack { Text("") }.frame(width: 40)
                    ForEach(0..<7) { idx in
                        let day = Calendar.current.date(byAdding: .day, value: idx, to: weekStart)!
                        VStack {
                            Text(DateFormatter.weekdayFormatter.string(from: day))
                            Text(DateFormatter.dayFormatter.string(from: day))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                ForEach(0..<24) { hour in
                    HStack(spacing: 0) {
                        Text(String(format: "%02d", hour))
                            .frame(width: 40)
                        ForEach(0..<7) { idx in
                            let day = Calendar.current.date(byAdding: .day, value: idx, to: weekStart)!
                            ZStack {
                                Rectangle().fill(Color.clear)
                                HourEventView(hour: hour, day: day, events: events)
                            }
                            .frame(width: 80, height: 60)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let tapped = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
                                print("tap on cell of \(DateFormatter.fullDateFormatter.string(from: tapped))")
                            }
                        }
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
                Button(action: { month = Calendar.current.date(byAdding: .month, value: -1, to: month)! }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(DateFormatter.monthYearFormatter.string(from: month))
                Spacer()
                Button(action: { month = Calendar.current.date(byAdding: .month, value: 1, to: month)! }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            Divider()
            let gridItems = Array(repeating: GridItem(.flexible()), count: 7)
            // MARK: - Month View Event Filtering ပြင်ချက်
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach(DateHelper.makeMonthGrid(for: month), id: \.self) { date in
                    CalendarCell(
                        date: date,
                        // start date နဲ့ compare ပြောင်းပြီး filter
                        events: events.filter {
                            if let d = date {
                                return Calendar.current.isDate($0.start, inSameDayAs: d)
                            }
                            return false
                        },
                        isCurrentMonth: date.map {
                            Calendar.current.isDate($0, equalTo: month, toGranularity: .month)
                        } ?? false
                    )
                    .frame(height: 60)
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
        guard let monthInterval = cal.dateInterval(of: .month, for: date) else { return [] }
        let startWeekday = cal.component(.weekday, from: monthInterval.start) - 1
        let days = cal.range(of: .day, in: .month, for: date)!
        var grid: [Date?] = Array(repeating: nil, count: startWeekday)
        for day in days {
            if let d = cal.date(bySetting: .day, value: day, of: date) {
                grid.append(d)
            }
        }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd"
        return f
    }()
    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
    static let weekdayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        return f
    }()
    static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    static let simpleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()
    static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd-MM-yyyy HH:mm"
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

// MARK: - Preview ContentView Usage
struct ContentView: View {
    var body: some View {
        CalendarView(events: sampleEvents)
    }
}

// MARK: - Sample Events ပြင်ချက်
let sampleEvents: [CalendarEvent] = {
    let cal = Calendar.current
    var arr: [CalendarEvent] = []
    // တစ်နေ့ ဗဟိုထားပြီး example events ၂ ခုပြ တဲ့အတွက်
    if let start1 = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
       let end1   = cal.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) {
        arr.append(.init(start: start1, end: end1, label: "Meeting", color: .orange))
    }
    if let start2 = cal.date(bySettingHour: 14, minute: 15, second: 0, of: Date()),
       let end2   = cal.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) {
        arr.append(.init(start: start2, end: end2, label: "test", color: .red))
    }
    return arr
}()

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

