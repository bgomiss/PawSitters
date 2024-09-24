//
//  SideMenuView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.09.2024.
//

import SwiftUI

struct FilterMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
    @State var isExpanded: Bool = false
    @ObservedObject var firestoreService: FirestoreService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @State var location: String
    @State var selectedDateRange: ClosedRange<Date>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                    if isShowing {
                        Rectangle()
                            .opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { isShowing.toggle() }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 32) {
                            SideFilterMenu(selectedTab: $selectedTab, isExpanded: isShowing, location: $location, selectedDateRange: $selectedDateRange)
                            Button(action: {
                                if let user = authService.user {
                                    userProfileService.fetchUserProfile(uid: user.uid) { result in
                                        switch result {
                                        case .success(let profile):
                                            DispatchQueue.main.async {
                                                userProfileService.userProfile = profile
                                                    if let dateRange = selectedDateRange, !location.isEmpty {
                                                        firestoreService.fetchByLocationAndDateRange(for:profile.role, location:location, dateRange:dateRange)
                                                            } else if let dateRange = selectedDateRange {
                                                                firestoreService.fetchByDateRange(for: profile.role,dateRange: dateRange)
                                                                } else if !location.isEmpty {
                                                                    firestoreService.fetchByLocation(for: profile.role,location: location)
                                                            }
                                                        }
                                        case .failure(let error):
                                            print("Error fetching user profile: \(error.localizedDescription)")
                                        }
                                    }
                                }
                                isShowing.toggle()
                            }, label: {
                                Text("Filter")
                                    .foregroundStyle(.blue)
                                    .frame(width: 210, height: 44)
                                    .background(.blue.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            })
                            Spacer()
                        }
                        .padding()
                        .frame(width: 250, alignment: .leading)
                        .background(Color.white)
                        
                        Spacer()
                    }
                .transition(.move(edge: .leading))
                .animation(.easeInOut, value: isShowing)
                .ignoresSafeArea()
                
            }
        }
    }
}

struct FilterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        FilterMenuView(isShowing: .constant(true), selectedTab: .constant(0), isExpanded: true, firestoreService: FirestoreService(), location: "manhattan")
    }
}
