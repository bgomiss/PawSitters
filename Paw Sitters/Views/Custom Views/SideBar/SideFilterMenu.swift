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
                Button(action: {
                    opOptionTapped(option)
                }, label: {
                    SideMenuRowView(isExpanded: $isExpanded, option: option, selectedOption: $selectedOption, selectedTab: $selectedTab, location: $location, selectedDateRange: $selectedDateRange)
                })
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
        selectedOption = option
        selectedTab = option.rawValue
    }
}

