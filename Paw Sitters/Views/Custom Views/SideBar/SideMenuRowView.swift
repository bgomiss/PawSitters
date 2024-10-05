//
//  SideMenuRowView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.09.2024.
//

import SwiftUI
import FirebaseFirestore

struct SideMenuRowView: View {
    let option: SideMenuOptionModel
    @Binding var isExpanded: Bool
    @Binding var selectedOption: SideMenuOptionModel?
    @Binding var selectedTab: Int
    @Binding var location: String
    @Binding var selectedDateRange: ClosedRange<Date>?
    
    private var isSelected: Bool {
        selectedOption == option
    }
        
    var body: some View {
      //  ZStack {
            NavigationStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: option.systemImageName)
                            .imageScale(.small)
                        
                        Text(option.title)
                            .font(.subheadline)
                        
                        Button(action: {
                            withAnimation {
                                if isSelected {
                                    selectedOption = option
                                    selectedTab = option.rawValue
                                } else {
                                    selectedOption = nil
                                }
                            }
                        }) {
                            Image(systemName: option.chevronImageName(isSelected: isSelected))
                                .rotationEffect(.degrees(isSelected ? 180 : 90))
                                .animation(.snappy, value: isSelected)
                                .foregroundStyle(.black)
                           
                        }
                        
                        Spacer()
                    }
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .frame(width: 210, height: 44)
                    .background(isSelected ? .blue.opacity(0.15) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.leading)
                }
                
                if isSelected {
                    TabView(selection: $selectedTab)  {
                        DatePickerView(selectedDateRange: $selectedDateRange)
                            .frame(width: 200, height: 200)
                            .tag(0)
                        LocationPickerView(location: $location)
                            .padding(.top, 1)
                            .frame(width: 200, height: 200)
                           // .background(Color(.green))
                            .tag(1)
                    }
                    .frame(height: 300)
                }
            }
        //}
    }
}

#Preview {
    let startDate = Date()
    let endDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))!
    SideMenuRowView(
        option: .location,
        isExpanded: .constant(true),
        selectedOption: .constant(.location),
        selectedTab: .constant(1),
        location: .constant("manhattan"),
        selectedDateRange: .constant(startDate...endDate)  // Tarih aralığı tanımlıyoruz
    )
}

struct DatePickerView: View {
    
    private let calendar = Calendar.current
    private let startDate: Date
    private let endDate: Date
    
    @Binding var selectedDateRange: ClosedRange<Date>?
    
    init(selectedDateRange: Binding<ClosedRange<Date>?>) {
        self._selectedDateRange = selectedDateRange
        self.startDate = Date()
        self.endDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
    }
    
    var body: some View {
        HorizonCalendar(calendar: calendar, monthsLayout: .vertical, selectedDateRange: $selectedDateRange)
            .onChange(of: selectedDateRange) {_, newValue in
                // Seçilen tarih aralığı değiştiğinde bir işlem yapabilirsiniz.
                print("Selected Date Range: \(String(describing: newValue))")
        }
    }
}

struct LocationPickerView: View {
    
    @StateObject private var viewModel = LocationViewModel()
    @Binding var location: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Choose your location", text: $viewModel.location)
                    .font(.subheadline)
            }
            .frame(height: 44)
            .padding(.horizontal)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(Color(.systemGray4))
            }
            
            if !viewModel.citySuggestions.isEmpty {
                    List(viewModel.citySuggestions) { city in
                        Text(city.name)
                            .onTapGesture {
                                viewModel.location = city.name
                                location = city.name
                                viewModel.fetchCoordinates(for: city)
                                viewModel.citySuggestions = []                                     }
                    }
                .frame(maxWidth: .infinity)              
                }
            }
        .padding(.top, -40)
        }
    }
