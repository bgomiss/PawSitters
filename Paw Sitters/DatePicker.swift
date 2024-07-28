////
////  DatePicker.swift
////  Paw Sitters
////
////  Created by aycan duskun on 24.07.2024.
////
//
//import SwiftUI
//
//struct CalendarView: View {
//    @Binding var startDate: Date?
//    @Binding var endDate: Date?
//    
//    private let calendar = Calendar.current
//    private let month: Date
//    
//    init(month: Date, startDate: Binding<Date?>, endDate: Binding<Date?>) {
//        self.month = month
//        self._startDate = startDate
//        self._endDate = endDate
//    }
//    
//    private var days: [Date] {
//        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
//              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
//            return []
//        }
//        
//        let days = calendar.generateDates(
//            inside: monthInterval,
//            matching: DateComponents(hour: 0, minute: 0, second: 0)
//        )
//        
//        // Add padding days to align the first day of the month with the correct weekday
//        let prefixDays = Array(repeating: Date(), count: calendar.component(.weekday, from: monthStart) - 1)
//        return prefixDays + days
//    }
//    
//    var body: some View {
//        VStack {
//            HStack {
//                Text(monthFormatted(month))
//                    .font(.headline)
//                    .padding()
//                Spacer()
//            }
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
//                ForEach(days, id: \.self) { date in
//                    if calendar.isDate(date, equalTo: month, toGranularity: .month) {
//                        DayVieww(date: date, startDate: $startDate, endDate: $endDate)
//                            .onTapGesture {
//                                handleDateSelection(date)
//                            }
//                    } else {
//                        Color.clear
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//    
//    private func monthFormatted(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM yyyy"
//        return formatter.string(from: date)
//    }
//    
//    private func handleDateSelection(_ date: Date) {
//        if startDate == nil || (startDate != nil && endDate != nil) {
//            startDate = date
//            endDate = nil
//        } else if let start = startDate {
//            if date < start {
//                startDate = date
//            } else {
//                endDate = date
//            }
//        }
//    }
//}
//
//extension Calendar {
//    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
//        var dates: [Date] = []
//        dates.append(interval.start)
//        
//        enumerateDates(
//            startingAfter: interval.start,
//            matching: components,
//            matchingPolicy: .nextTime
//        ) { date, _, stop in
//            if let date = date {
//                if date < interval.end {
//                    dates.append(date)
//                } else {
//                    stop = true
//                }
//            }
//        }
//        
//        return dates
//    }
//}
//
//struct DayVieww: View {
//    let date: Date
//    @Binding var startDate: Date?
//    @Binding var endDate: Date?
//    
//    var body: some View {
//        Text(dateFormatted(date))
//            .font(.body)
//            .padding(10)
//            .background(isSelected(date) ? Color.blue : Color.clear)
//            .cornerRadius(8)
//            .foregroundColor(isSelected(date) ? Color.white : Color.black)
//    }
//    
//    private func dateFormatted(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "d"
//        return formatter.string(from: date)
//    }
//    
//    private func isSelected(_ date: Date) -> Bool {
//        if let start = startDate, let end = endDate {
//            return date >= start && date <= end
//        } else if let start = startDate {
//            return date == start
//        }
//        return false
//    }
//}

