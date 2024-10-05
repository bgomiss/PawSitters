//
//  SideMenu.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.09.2024.
//

import SwiftUI

struct SideFilterMenu: View {
    @Binding var selectedTab: Int
    @State var isExpanded: Bool
    @State private var selectedOption: SideMenuOptionModel?
    @Binding var location: String
    @Binding var selectedDateRange: ClosedRange<Date>?
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Filter Options")
                    .font(.headline)
                    .padding(.top, 20)
                    .padding(.leading, 16)
                ForEach(SideMenuOptionModel.allCases) { option in
                    SideMenuRowView(option: option,
                                    isExpanded: $isExpanded,
                                    selectedOption: $selectedOption,
                                    selectedTab: $selectedTab,
                                    location: $location,
                                    selectedDateRange: $selectedDateRange)
                    .onTapGesture {
                        opOptionTapped(option)
                    }
                    //                if option == .date {
                    //                    if isExpanded {
                    //                        VStack(alignment: .leading) {
                    //                            Text("Anahtar kelimeleri otomatik olarak bulun")
                    //                            Text("Hedef anahtar kelimeler veya ürünler")
                    //                        }
                    //                    }
                    //                } else if option == .location {
                    //                    if isExpanded {
                    //                        Text("Anahtar kelimeletik olarak bulun")
                    //                        Text("Hedef anahtar k")
                    //                    }
                    //                }
                }
                //            Text("Filter Options")
                //                .font(.headline)
                //                .padding(.top, 20)
                //
                //            // Add filter options here
                //            Button("Date") {
                //                // Filter by date action
                //            }
                //            .padding()
                //
                //            Button("Location") {
                //                // Filter by location action
                //            }
                //            .padding()
                //
                //            Button("Animal Type") {
                //                // Filter by animal type action
                //            }
                //            .padding()
            }
            
        }
        .padding(.top, 50)
        .navigationBarTitleDisplayMode(.inline)
    }
    private func opOptionTapped(_ option: SideMenuOptionModel) {
        if selectedOption == option {
            // If the option is already selected, deselect it
            selectedOption = nil
        }  else {
            selectedOption = option
            selectedTab = option.rawValue
        }
    }
}

struct SideFilterMenu_Previews: PreviewProvider {
    static var previews: some View {
        let startDate = Date()
            let endDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        SideFilterMenu(selectedTab: .constant(1), isExpanded: true, location: .constant("manhattan"), selectedDateRange: .constant(startDate...endDate))
    }
}
