//
//  SitterListingsView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

//import SwiftUI
//
//struct SitterListingsView: View {
//    @EnvironmentObject var userProfileService: UserProfileService
//    @State private var sitters: [UserProfile] = []
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Available Sitters")
//                    .font(.largeTitle)
//                    .padding()
//                
//                List(sitters) { sitter in
//                    VStack(alignment: .leading) {
//                        Text(sitter.name ?? "Not Found")
//                            .font(.headline)
//                        Text(sitter.email ?? "Email Not Found")
//                        if let imageUrl = sitter.profileImageUrl, let url = URL(string: imageUrl) {
//                            AsyncImage(url: url)
//                                .aspectRatio(contentMode: .fill)
//                                .frame(width: 100, height: 100)
//                                .clipShape(RoundedRectangle(cornerRadius: 10))
//                        }
//                        Text(sitter.description ?? "")
//                    }
//                }
//                .onAppear {
//                    userProfileService.fetchUserProfiles(from: "sitters") { result in
//                        switch result {
//                        case .success(let fetchedSitters):
//                            self.sitters = fetchedSitters
//                        case .failure(let error):
//                            print("Error fetching sitters: \(error.localizedDescription)")
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct SitterListingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SitterListingsView()
//            .environmentObject(UserProfileService())
//    }
//}





