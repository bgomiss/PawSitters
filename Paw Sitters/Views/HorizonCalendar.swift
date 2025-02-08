//
//  HorizonCalendar.swift
//  Paw Sitters
//
//  Created by aycan duskun on 26.07.2024.
//

import SwiftUI
import HorizonCalendar

struct HorizonCalendarView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> CalendarView {
        let calendarView = CalendarView(initialContent: makeContent())
        return calendarView
    }

    func updateUIView(_ uiView: CalendarView, context: Context) {
        // Güncelleme gerektiren durumlar için gerekli kodları buraya ekleyin
    }

    private func makeContent() -> CalendarViewContent {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2020, month: 01, day: 01))!
        let endDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!

        let calendarViewContent = CalendarViewContent(
            calendar: calendar,
            visibleDateRange: startDate...endDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions())
        )
        .withDayItemProvider { day in
            var invariantViewProperties = DayView.InvariantViewProperties.baseInteractive

            return DayView.dayItemModel(
                invariantViewProperties: invariantViewProperties,
                content: .init(
                    backgroundShape: .circle,
                    text: "\(day.day)"
                )
            )
        }
        return calendarViewContent
    }
}

#Preview {
    HorizonCalendar()
}
