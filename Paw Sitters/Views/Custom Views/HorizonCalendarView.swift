//
//  HorizonCalendarView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 27.07.2024.
//

import SwiftUI
import HorizonCalendar

struct HorizonCalendar: View {
    let calendar: Calendar
    let monthsLayout: MonthsLayout
    @Binding var selectedDateRange: ClosedRange<Date>?

    private let visibleDateRange: ClosedRange<Date>
    private let monthDateFormatter: DateFormatter

    @StateObject private var calendarViewProxy = CalendarViewProxy()

    init(calendar: Calendar, monthsLayout: MonthsLayout, selectedDateRange: Binding<ClosedRange<Date>?>) {
        self.calendar = calendar
        self.monthsLayout = monthsLayout
        self._selectedDateRange = selectedDateRange
        let today = Date()
        //let startDate = calendar.date(from: DateComponents(year: 2023, month: 01, day: 01))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        visibleDateRange = today...endDate

        monthDateFormatter = DateFormatter()
        monthDateFormatter.calendar = calendar
        monthDateFormatter.locale = calendar.locale
        monthDateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "MMMM yyyy",
            options: 0,
            locale: calendar.locale ?? Locale.current)
    }

    var body: some View {
        
        CalendarViewRepresentable(
            calendar: calendar,
            visibleDateRange: visibleDateRange,
            monthsLayout: monthsLayout,
            dataDependency: selectedDateRange,
            proxy: calendarViewProxy)

        .interMonthSpacing(24)
        .verticalDayMargin(8)
        .horizontalDayMargin(8)

        .monthHeaders { month in
            let monthHeaderText = monthDateFormatter.string(from: calendar.date(from: month.components)!)
            Group {
                if case .vertical = monthsLayout {
                    HStack {
                        Text(monthHeaderText)
                            .font(.title2)
                        Spacer()
                    }
                    .padding()
                } else {
                    Text(monthHeaderText)
                        .font(.title2)
                        .padding()
                }
            }
            .accessibilityAddTraits(.isHeader)
        }

        .days { day in
            DayView(dayNumber: day.day, isSelected: isDaySelected(day))
                .onTapGesture {
                    
                    var components = day.components
                    components.hour = 12
                    
                    
                    guard let dayDate = calendar.date(from: components) else { return }
                       
                    switch selectedDateRange {
                    case nil:
                        // İlk tıklama: aralığı başlat
                        self.selectedDateRange = dayDate...dayDate

                    case let range? where range.lowerBound == dayDate || range.upperBound == dayDate:
                        // Eğer seçilen gün mevcut aralığın sınırına eşitse: aralığı sıfırla
                        self.selectedDateRange = nil
//                        
//                    case let range? where range.contains(dayDate):
//                        // Eğer seçilen gün mevcut aralığın içindeyse: aralığı sıfırla
//                        self.selectedDateRange = nil

                    case let range? where range.lowerBound != dayDate && range.upperBound != dayDate && !range.contains(dayDate) && range.lowerBound != range.upperBound || range.contains(dayDate):
                        // Eğer seçilen gün mevcut aralığın dışında ve aralık iki tarihi kapsıyorsa: aralığı sıfırla
                        self.selectedDateRange = dayDate...dayDate

                    case let range?:
                        // İkinci tıklama: aralığı genişlet
                        self.selectedDateRange = min(range.lowerBound, dayDate)...max(range.upperBound, dayDate)
                    }
                }
            }




        .onAppear {
            let today = Date()
            calendarViewProxy.scrollToDay(
                containing: today,
                scrollPosition: .centered,
                animated: true)
        }

        .frame(maxWidth: 375, maxHeight: .infinity)
    }

    private func isDaySelected(_ day: DayComponents) -> Bool {
        guard let selectedDateRange else { return false }
        
        var components = day.components
        components.hour = 12 // Gün ortasına ayarlayarak olası zaman kaymalarını önle

        let dayDate = calendar.date(from: components)!
        return selectedDateRange.contains(dayDate)
    }
}

struct DayView: View {
    let dayNumber: Int
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                .background {
                    Circle()
                        .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .clear)
                }
                .aspectRatio(1, contentMode: .fill)
            Text("\(dayNumber)").foregroundColor(Color(UIColor.label))
        }
        .accessibilityAddTraits(.isButton)
    }
}
